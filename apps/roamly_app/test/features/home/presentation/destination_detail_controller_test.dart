import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_collection_query.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_detail.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_page.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_place_detail.dart';
import 'package:roamly_app/src/features/home/domain/entities/home_discovery.dart';
import 'package:roamly_app/src/features/home/domain/entities/map_location.dart';
import 'package:roamly_app/src/features/home/domain/failures/destination_detail_failure.dart';
import 'package:roamly_app/src/features/home/domain/repositories/home_discovery_repository.dart';
import 'package:roamly_app/src/features/home/presentation/controllers/destination_detail_controller.dart';
import 'package:roamly_app/src/features/home/presentation/providers/home_dependency_providers.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';
import 'package:roamly_core/roamly_core.dart';

DestinationDetail _detail({
  String slug = 'bali-indonesia',
  String name = 'Bali',
}) {
  return DestinationDetail(
    id: '00000000-0000-4000-8000-000000000001',
    slug: slug,
    name: name,
    type: DestinationType.island,
    countryName: 'Indonesia',
    countryCode: 'ID',
    summary: 'A tropical island rich in culture and natural beauty.',
    fullDescription:
        'Explore beaches, temples, local traditions, and scenic landscapes.',
    location: const MapLocation(
      latitude: -8.4095,
      longitude: 115.1889,
      mapZoom: 9,
    ),
    budgetTier: BudgetTier.midRange,
    styles: const [TravelStyle.beaches],
    interests: const [TravelInterest.photography],
    gallery: const [],
    places: const [],
    placesNextCursor: null,
  );
}

final class _Repository implements HomeDiscoveryRepository {
  final slugs = <String>[];

  Result<DestinationDetail> result = Success(_detail());
  Completer<Result<DestinationDetail>>? pending;
  Object? exception;

  @override
  Future<Result<DestinationDetail>> getDestinationDetail({
    required String slug,
  }) async {
    slugs.add(slug);

    if (exception case final error?) {
      throw error;
    }

    return pending?.future ?? result;
  }

  @override
  Future<Result<HomeDiscovery>> getHome({required int limit}) {
    throw StateError('Unexpected Home request.');
  }

  @override
  Future<Result<DestinationPage>> getDestinations({
    required DestinationCollectionQuery query,
    int limit = 20,
    String? cursor,
  }) {
    throw StateError('Unexpected destination collection request.');
  }

  @override
  Future<Result<DestinationPlaceDetail>> getDestinationPlaceDetail({
    required String destinationSlug,
    required String placeSlug,
  }) {
    throw StateError('Unexpected destination place detail request.');
  }
}

void main() {
  const slug = 'bali-indonesia';
  final provider = destinationDetailControllerProvider(slug);

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
    container.listen(provider, (_, _) {});
  }

  Future<DestinationDetail> load() {
    watch();
    return container.read(provider.future);
  }

  DestinationDetailController controller() {
    return container.read(provider.notifier);
  }

  test('loads lazily and forwards the exact slug', () async {
    expect(repository.slugs, isEmpty);

    final pending = Completer<Result<DestinationDetail>>();
    repository.pending = pending;

    final future = load();

    expect(container.read(provider).isLoading, isTrue);
    expect(repository.slugs, [slug]);

    final detail = _detail();
    pending.complete(Success(detail));

    expect(await future, same(detail));
    expect(container.read(provider).requireValue, same(detail));
    expect(repository.slugs, [slug]);
  });

  test('exposes initial failure without automatic retry', () async {
    const failure = DestinationDetailFailure.notFound();
    repository.result = const FailureResult(failure);

    await expectLater(load(), throwsA(same(failure)));
    await container.pump();

    expect(container.read(provider).error, same(failure));
    expect(repository.slugs, [slug]);
  });

  test('explicit retry recovers an initial failure', () async {
    const failure = DestinationDetailFailure.invalidResponse();
    repository.result = const FailureResult(failure);

    await expectLater(load(), throwsA(same(failure)));

    final recovered = _detail(name: 'Updated Bali');
    repository.result = Success(recovered);

    expect(await controller().retry(), isTrue);
    expect(container.read(provider).requireValue, same(recovered));
    expect(repository.slugs, [slug, slug]);
  });

  test('concurrent retry does not duplicate the request', () async {
    const failure = DestinationDetailFailure.invalidResponse();
    repository.result = const FailureResult(failure);

    await expectLater(load(), throwsA(same(failure)));

    final pending = Completer<Result<DestinationDetail>>();
    repository.pending = pending;

    final firstRetry = controller().retry();

    expect(container.read(provider).isLoading, isTrue);
    expect(await controller().retry(), isFalse);
    expect(repository.slugs, [slug, slug]);

    pending.complete(Success(_detail()));

    expect(await firstRetry, isTrue);
    expect(repository.slugs, [slug, slug]);
  });

  test('retry is ignored when detail is already successful', () async {
    await load();

    expect(await controller().retry(), isFalse);
    expect(repository.slugs, [slug]);
  });

  test('successful detail remains cached after listener closes', () async {
    final subscription = container.listen(provider, (_, _) {});

    final detail = await container.read(provider.future);

    subscription.close();
    await container.pump();

    final nextSubscription = container.listen(provider, (_, _) {});
    final cached = await container.read(provider.future);

    expect(cached, same(detail));
    expect(repository.slugs, [slug]);

    nextSubscription.close();
  });

  test('different slugs use independent provider instances', () async {
    final kyotoProvider = destinationDetailControllerProvider('kyoto-japan');

    container.listen(provider, (_, _) {});
    container.listen(kyotoProvider, (_, _) {});

    await Future.wait([
      container.read(provider.future),
      container.read(kyotoProvider.future),
    ]);

    expect(repository.slugs, containsAll([slug, 'kyoto-japan']));
    expect(repository.slugs, hasLength(2));
  });

  test('retry completion after disposal does not update state', () async {
    const failure = DestinationDetailFailure.invalidResponse();
    repository.result = const FailureResult(failure);

    await expectLater(load(), throwsA(same(failure)));

    final pending = Completer<Result<DestinationDetail>>();
    repository.pending = pending;

    final retry = controller().retry();

    container.dispose();
    pending.complete(Success(_detail()));

    expect(await retry, isFalse);
  });
}
