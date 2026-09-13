import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_collection_query.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_detail.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_page.dart';
import 'package:roamly_app/src/features/home/domain/entities/home_discovery.dart';
import 'package:roamly_app/src/features/home/domain/failures/destination_catalogue_failure.dart';
import 'package:roamly_app/src/features/home/domain/repositories/home_discovery_repository.dart';
import 'package:roamly_app/src/features/home/presentation/controllers/destination_collection_controller.dart';
import 'package:roamly_app/src/features/home/presentation/providers/home_dependency_providers.dart';
import 'package:roamly_app/src/features/home/presentation/state/destination_collection_state.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';
import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_networking/roamly_networking.dart';

Destination _destination(String id) => Destination(
  id: id,
  slug: id,
  name: id,
  countryName: 'Pakistan',
  countryCode: 'PK',
  summary: 'Destination $id',
  imageUri: Uri.parse('https://example.test/$id.jpg'),
  imageAlt: id,
  latitude: 0,
  longitude: 0,
  budgetTier: BudgetTier.midRange,
  styles: const [TravelStyle.nature],
  interests: const [TravelInterest.hiking],
);

Result<DestinationPage> _page(List<String> ids, {String? next = 'page-2'}) =>
    Success(DestinationPage(items: ids.map(_destination), nextCursor: next));

final class _Repository implements HomeDiscoveryRepository {
  final calls =
      <({DestinationCollectionQuery query, int limit, String? cursor})>[];
  Future<Result<DestinationPage>> Function(String? cursor) respond =
      (_) async => _page(['a']);

  @override
  Future<Result<DestinationPage>> getDestinations({
    required DestinationCollectionQuery query,
    int limit = 20,
    String? cursor,
  }) {
    calls.add((query: query, limit: limit, cursor: cursor));
    return respond(cursor);
  }

  @override
  Future<Result<HomeDiscovery>> getHome({required int limit}) =>
      throw StateError('Unexpected Home request');

  @override
  Future<Result<DestinationDetail>> getDestinationDetail({
    required String slug,
  }) => throw StateError('Unexpected destination detail request');
}

void main() {
  const query = DestinationCollectionQuery.popular();
  final provider = destinationCollectionControllerProvider(query);
  const timeout = NetworkFailure(
    code: 'network_timeout',
    isRetryable: true,
    kind: NetworkFailureKind.timeout,
  );
  late _Repository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _Repository();
    container = ProviderContainer.test(
      overrides: [
        homeDiscoveryRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  Future<DestinationCollectionState> load() {
    container.listen(provider, (_, _) {});
    return container.read(provider.future);
  }

  DestinationCollectionController controller() =>
      container.read(provider.notifier);
  DestinationCollectionState data() => container.read(provider).requireValue;

  test(
    'loads lazily, blocks duplicate initial requests and uses page size 20',
    () async {
      expect(repository.calls, isEmpty);
      final pending = Completer<Result<DestinationPage>>();
      repository.respond = (_) => pending.future;
      final future = load();
      expect(container.read(provider).isLoading, isTrue);
      expect(await controller().loadMore(), isFalse);
      expect(await controller().reload(), isFalse);
      pending.complete(_page(['a']));
      await future;
      expect(repository.calls, [(query: query, limit: 20, cursor: null)]);
      expect(data().items.single.id, 'a');
      expect(() => data().items.clear(), throwsUnsupportedError);
    },
  );

  test(
    'initial failure has no automatic retry and explicit reload recovers',
    () async {
      repository.respond = (_) async => const FailureResult(timeout);
      await expectLater(load(), throwsA(same(timeout)));
      await container.pump();
      expect(repository.calls, hasLength(1));
      expect(container.read(provider).error, same(timeout));
      repository.respond = (_) async => _page([], next: null);
      expect(await controller().reload(), isTrue);
      expect(data().isEmpty, isTrue);
      expect(await controller().loadMore(), isFalse);
      expect(repository.calls, hasLength(2));
    },
  );

  test(
    'forwards cursor, blocks overlapping loads and deduplicates by ID',
    () async {
      await load();
      final pending = Completer<Result<DestinationPage>>();
      repository.respond = (_) => pending.future;
      final request = controller().loadMore();
      expect(data().isLoadingMore, isTrue);
      expect(await controller().loadMore(), isFalse);
      expect(await controller().retryLoadMore(), isFalse);
      expect(repository.calls.last.cursor, 'page-2');
      pending.complete(_page(['a', 'b', 'b'], next: null));
      expect(await request, isTrue);
      expect(data().items.map((item) => item.id), ['a', 'b']);
      expect(data().hasMore, isFalse);
      expect(await controller().loadMore(), isFalse);
      expect(repository.calls, hasLength(2));
    },
  );

  test(
    'next-page failure preserves cards and requires explicit retry',
    () async {
      await load();
      repository.respond = (_) async => const FailureResult(timeout);
      expect(await controller().loadMore(), isFalse);
      expect(data().items.single.id, 'a');
      expect(data().nextCursor, 'page-2');
      expect(data().loadMoreFailure, same(timeout));
      expect(await controller().loadMore(), isFalse);
      expect(repository.calls, hasLength(2));
      repository.respond = (_) async => _page(['b'], next: null);
      expect(await controller().retryLoadMore(), isTrue);
      expect(repository.calls.last.cursor, 'page-2');
      expect(data().loadMoreFailure, isNull);
      expect(data().items.map((item) => item.id), ['a', 'b']);
    },
  );

  test(
    'stalled cursor stops automatic pagination and keeps loaded cards',
    () async {
      await load();
      repository.respond = (_) async => _page(['b']);
      expect(await controller().loadMore(), isFalse);
      expect(
        (data().loadMoreFailure as DestinationCatalogueFailure).kind,
        DestinationCatalogueFailureKind.invalidResponse,
      );
      expect(data().items.single.id, 'a');
      expect(await controller().loadMore(), isFalse);
      expect(repository.calls, hasLength(2));
    },
  );

  test(
    'invalid cursor restarts once from page one and replaces cards',
    () async {
      await load();
      repository.respond = (cursor) async => cursor == null
          ? _page(['new'], next: null)
          : const FailureResult(DestinationCatalogueFailure.invalidCursor());
      expect(await controller().loadMore(), isTrue);
      expect(repository.calls.map((call) => call.cursor), [
        null,
        'page-2',
        null,
      ]);
      expect(data().items.single.id, 'new');
    },
  );

  test(
    'failed invalid-cursor restart becomes initial error without a loop',
    () async {
      await load();
      const failure = DestinationCatalogueFailure.invalidCursor();
      repository.respond = (_) async => const FailureResult(failure);
      expect(await controller().loadMore(), isFalse);
      await container.pump();
      expect(repository.calls, hasLength(3));
      expect(container.read(provider).error, same(failure));
    },
  );

  for (final staleFailure in [false, true]) {
    test(
      'refresh ignores stale load-more ${staleFailure ? 'failure' : 'success'}',
      () async {
        await load();
        final pending = Completer<Result<DestinationPage>>();
        repository.respond = (cursor) => cursor == null
            ? Future.value(_page(['fresh'], next: null))
            : pending.future;
        final oldRequest = controller().loadMore();
        expect(await controller().reload(), isTrue);
        pending.complete(
          staleFailure ? const FailureResult(timeout) : _page(['old']),
        );
        expect(await oldRequest, isFalse);
        expect(data().items.single.id, 'fresh');
        expect(data().loadMoreFailure, isNull);
      },
    );
  }

  test('disposal ignores an in-flight load-more result', () async {
    await load();
    final notifier = controller();
    final pending = Completer<Result<DestinationPage>>();
    repository.respond = (_) => pending.future;
    final request = notifier.loadMore();
    container.dispose();
    pending.complete(_page(['late']));
    expect(await request, isFalse);
    expect(await notifier.loadMore(), isFalse);
    expect(await notifier.reload(), isFalse);
  });

  test(
    'family reuses equal queries and isolates different collections',
    () async {
      await load();
      final sameQuery = destinationCollectionControllerProvider(
        const DestinationCollectionQuery.popular(),
      );
      container.listen(sameQuery, (_, _) {});
      await container.read(sameQuery.future);
      final featured = destinationCollectionControllerProvider(
        const DestinationCollectionQuery.featured(),
      );
      container.listen(featured, (_, _) {});
      await container.read(featured.future);
      expect(repository.calls, hasLength(2));
      expect(
        container.read(provider.notifier),
        same(container.read(sameQuery.notifier)),
      );
      expect(
        container.read(provider.notifier),
        isNot(same(container.read(featured.notifier))),
      );
    },
  );

  test('unexpected errors propagate and release load-more state', () async {
    await load();
    final error = StateError('bug');
    repository.respond = (_) async => throw error;
    await expectLater(controller().loadMore(), throwsA(same(error)));
    expect(data().isLoadingMore, isFalse);
    expect(data().items.single.id, 'a');
  });
}
