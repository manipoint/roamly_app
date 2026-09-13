import 'dart:async';

import 'package:roamly_app/src/features/home/domain/entities/destination_collection_query.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_collection.dart';
import 'package:roamly_app/src/features/home/domain/entities/home_discovery.dart';
import 'package:roamly_app/src/features/home/domain/failures/home_discovery_failure.dart';
import 'package:roamly_app/src/features/home/domain/policies/home_discovery_policy.dart';
import 'package:roamly_app/src/features/home/domain/repositories/home_discovery_repository.dart';
import 'package:roamly_app/src/features/home/presentation/controllers/home_discovery_controller.dart';
import 'package:roamly_app/src/features/home/presentation/providers/home_dependency_providers.dart';
import 'package:roamly_core/roamly_core.dart';

HomeDiscovery _discovery({bool personalized = false}) => HomeDiscovery(
  personalizationReady: personalized,
  suggested: const [],
  popular: const [],
  spotlight: DestinationCollection(
    kind: DiscoveryCollectionKind.featured,
    items: const [],
  ),
);

final class _Repository implements HomeDiscoveryRepository {
  @override
  Future<Result<DestinationPage>> getDestinations({
    required DestinationCollectionQuery query,
    int limit = 20,
    String? cursor,
  }) => throw StateError('Unexpected catalogue request in Home-only test');

  final limits = <int>[];
  Result<HomeDiscovery> result = Success(_discovery());
  Completer<Result<HomeDiscovery>>? pending;
  Object? exception;

  @override
  Future<Result<HomeDiscovery>> getHome({required int limit}) async {
    limits.add(limit);
    if (exception case final error?) throw error;
    return pending?.future ?? result;
  }
}

void main() {
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

  void watch() {
    container.listen(homeDiscoveryControllerProvider, (_, _) {});
  }

  Future<HomeDiscovery> load() {
    watch();
    return container.read(homeDiscoveryControllerProvider.future);
  }

  HomeDiscoveryController controller() =>
      container.read(homeDiscoveryControllerProvider.notifier);

  test('loads lazily and uses the default section limit', () async {
    expect(repository.limits, isEmpty);
    final pending = Completer<Result<HomeDiscovery>>();
    repository.pending = pending;
    final future = load();
    expect(container.read(homeDiscoveryControllerProvider).isLoading, isTrue);
    final discovery = _discovery();
    pending.complete(Success(discovery));
    expect(await future, same(discovery));
    expect(
      container.read(homeDiscoveryControllerProvider).requireValue,
      same(discovery),
    );
    expect(repository.limits, [HomeDiscoveryPolicy.defaultSectionLimit]);
  });

  test('initial failure is exposed without automatic retries', () async {
    const failure = HomeDiscoveryFailure.invalidResponse();
    repository.result = const FailureResult(failure);
    await expectLater(load(), throwsA(same(failure)));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(
      container.read(homeDiscoveryControllerProvider).error,
      same(failure),
    );
    expect(repository.limits, hasLength(1));
  });

  test('reload replaces data and reports success', () async {
    await load();
    final pending = Completer<Result<HomeDiscovery>>();
    repository.pending = pending;
    final future = controller().reload();
    expect(container.read(homeDiscoveryControllerProvider).isLoading, isTrue);
    final updated = _discovery(personalized: true);
    pending.complete(Success(updated));
    expect(await future, isTrue);
    expect(
      container.read(homeDiscoveryControllerProvider).requireValue,
      same(updated),
    );
    expect(
      repository.limits,
      List.filled(2, HomeDiscoveryPolicy.defaultSectionLimit),
    );
  });

  test(
    'reload during initial loading does not duplicate the request',
    () async {
      final pending = Completer<Result<HomeDiscovery>>();
      repository.pending = pending;
      final future = load();
      expect(await controller().reload(), isFalse);
      expect(repository.limits, hasLength(1));
      pending.complete(Success(_discovery()));
      await future;
    },
  );

  test('concurrent reload is ignored', () async {
    await load();
    final pending = Completer<Result<HomeDiscovery>>();
    repository.pending = pending;
    final first = controller().reload();
    expect(await controller().reload(), isFalse);
    expect(repository.limits, hasLength(2));
    pending.complete(Success(_discovery()));
    expect(await first, isTrue);
  });

  test('reload exposes domain failures and allows explicit recovery', () async {
    await load();
    const failure = HomeDiscoveryFailure.invalidResponse();
    repository.result = const FailureResult(failure);
    expect(await controller().reload(), isFalse);
    expect(
      container.read(homeDiscoveryControllerProvider).error,
      same(failure),
    );
    final recovered = _discovery();
    repository.result = Success(recovered);
    expect(await controller().reload(), isTrue);
    expect(
      container.read(homeDiscoveryControllerProvider).requireValue,
      same(recovered),
    );
  });

  test('initial failure can be retried explicitly', () async {
    const failure = HomeDiscoveryFailure.invalidResponse();
    repository.result = const FailureResult(failure);
    await expectLater(load(), throwsA(same(failure)));
    repository.result = Success(_discovery());
    expect(await controller().reload(), isTrue);
    expect(repository.limits, hasLength(2));
  });

  test('unexpected repository exceptions become error state', () async {
    await load();
    final error = StateError('unexpected repository error');
    repository.exception = error;
    expect(await controller().reload(), isFalse);
    expect(container.read(homeDiscoveryControllerProvider).error, same(error));
  });

  test('pending reload completes safely after disposal', () async {
    await load();
    final pending = Completer<Result<HomeDiscovery>>();
    repository.pending = pending;
    final future = controller().reload();
    container.dispose();
    pending.complete(Success(_discovery()));
    expect(await future, isFalse);
  });

  test('reload after disposal returns false without a request', () async {
    await load();
    final notifier = controller();
    container.dispose();

    expect(await notifier.reload(), isFalse);
    expect(repository.limits, hasLength(1));
  });

  for (final fails in [false, true]) {
    test(
      'stale reload ${fails ? 'failure' : 'success'} cannot replace rebuilt data',
      () async {
        await load();
        final notifier = controller();
        final pending = Completer<Result<HomeDiscovery>>();
        repository.pending = pending;
        final staleReload = notifier.reload();

        final fresh = _discovery(personalized: true);
        final replacement = _Repository()..result = Success(fresh);
        container.updateOverrides([
          homeDiscoveryRepositoryProvider.overrideWithValue(replacement),
        ]);

        expect(
          await container.read(homeDiscoveryControllerProvider.future),
          same(fresh),
        );
        expect(controller(), same(notifier));

        pending.complete(
          fails
              ? const FailureResult(HomeDiscoveryFailure.invalidResponse())
              : Success(_discovery()),
        );

        expect(await staleReload, isFalse);
        expect(
          container.read(homeDiscoveryControllerProvider).requireValue,
          same(fresh),
        );
        expect(repository.limits, hasLength(2));
        expect(replacement.limits, [HomeDiscoveryPolicy.defaultSectionLimit]);

        // Ignoring an old response must not prevent subsequent refreshes.
        final refreshed = _discovery();
        replacement.result = Success(refreshed);
        expect(await notifier.reload(), isTrue);
        expect(
          container.read(homeDiscoveryControllerProvider).requireValue,
          same(refreshed),
        );
        expect(replacement.limits, hasLength(2));
      },
    );
  }
}
