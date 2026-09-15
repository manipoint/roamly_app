import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_collection_query.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_detail.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_page.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_place_detail.dart';
import 'package:roamly_app/src/features/home/domain/entities/home_discovery.dart';
import 'package:roamly_app/src/features/home/domain/entities/map_location.dart';
import 'package:roamly_app/src/features/home/domain/failures/destination_place_detail_failure.dart';
import 'package:roamly_app/src/features/home/domain/repositories/home_discovery_repository.dart';
import 'package:roamly_app/src/features/home/presentation/controllers/destination_place_detail_controller.dart';
import 'package:roamly_app/src/features/home/presentation/providers/home_dependency_providers.dart';
import 'package:roamly_core/roamly_core.dart';

DestinationPlaceDetail _detail({String placeSlug = 'meiji-shrine'}) {
  return DestinationPlaceDetail(
    destinationSlug: 'tokyo-japan',
    place: DestinationPlacePreview(
      id: '00000000-0000-4000-8000-000000000001',
      slug: placeSlug,
      name: 'Meiji Shrine',
      placeType: 'religious_site',
      summary: 'Visit a peaceful shrine surrounded by a large forest in Tokyo.',
      location: const MapLocation(latitude: 35.6748, longitude: 139.6996),
      address: '1 Yoyogi Kamizonocho, Shibuya, Tokyo',
      isFeatured: true,
      coverImage: null,
    ),
    fullDescription:
        'Meiji Shrine is a peaceful Shinto shrine surrounded by a forest '
        'in the centre of Tokyo.',
    gallery: const [],
  );
}

final class _Repository implements HomeDiscoveryRepository {
  final calls = <({String destinationSlug, String placeSlug})>[];

  Result<DestinationPlaceDetail> result = Success(_detail());
  Completer<Result<DestinationPlaceDetail>>? pending;

  @override
  Future<Result<DestinationPlaceDetail>> getDestinationPlaceDetail({
    required String destinationSlug,
    required String placeSlug,
  }) {
    calls.add((destinationSlug: destinationSlug, placeSlug: placeSlug));
    return pending?.future ?? Future.value(result);
  }

  @override
  Future<Result<DestinationDetail>> getDestinationDetail({
    required String slug,
  }) => throw StateError('Unexpected destination detail request.');

  @override
  Future<Result<DestinationPage>> getDestinations({
    required DestinationCollectionQuery query,
    int limit = 20,
    String? cursor,
  }) => throw StateError('Unexpected destination collection request.');

  @override
  Future<Result<HomeDiscovery>> getHome({required int limit}) {
    throw StateError('Unexpected Home request.');
  }
}

void main() {
  const request = (destinationSlug: 'tokyo-japan', placeSlug: 'meiji-shrine');
  final provider = destinationPlaceDetailControllerProvider(request);

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

  Future<DestinationPlaceDetail> load() {
    container.listen(provider, (_, _) {});
    return container.read(provider.future);
  }

  DestinationPlaceDetailController controller() {
    return container.read(provider.notifier);
  }

  test('loads lazily and forwards both route slugs', () async {
    expect(repository.calls, isEmpty);

    final detail = await load();

    final expected =
        (repository.result as Success<DestinationPlaceDetail>).value;
    expect(detail, same(expected));
    expect(repository.calls, [request]);
  });

  test('exposes failure and explicit retry can recover', () async {
    const failure = DestinationPlaceDetailFailure.notFound();
    repository.result = const FailureResult(failure);

    await expectLater(load(), throwsA(same(failure)));

    final recovered = _detail();
    repository.result = Success(recovered);

    expect(await controller().retry(), isTrue);
    expect(container.read(provider).requireValue, same(recovered));
    expect(repository.calls, [request, request]);
  });

  test('concurrent retry does not issue a duplicate request', () async {
    const failure = DestinationPlaceDetailFailure.invalidResponse();
    repository.result = const FailureResult(failure);

    await expectLater(load(), throwsA(same(failure)));

    final pending = Completer<Result<DestinationPlaceDetail>>();
    repository.pending = pending;

    final firstRetry = controller().retry();

    expect(container.read(provider).isLoading, isTrue);
    expect(await controller().retry(), isFalse);
    expect(repository.calls, [request, request]);

    pending.complete(Success(_detail()));

    expect(await firstRetry, isTrue);
    expect(repository.calls, [request, request]);
  });

  test('retry is ignored after a successful load', () async {
    await load();

    expect(await controller().retry(), isFalse);
    expect(repository.calls, [request]);
  });

  test('successful detail remains cached after listener closes', () async {
    final subscription = container.listen(provider, (_, _) {});
    final detail = await container.read(provider.future);

    subscription.close();
    await container.pump();

    final nextSubscription = container.listen(provider, (_, _) {});
    final cached = await container.read(provider.future);

    expect(cached, same(detail));
    expect(repository.calls, [request]);

    nextSubscription.close();
  });

  test('different route pairs use independent provider instances', () async {
    const secondRequest = (
      destinationSlug: 'tokyo-japan',
      placeSlug: 'senso-ji',
    );
    final secondProvider = destinationPlaceDetailControllerProvider(
      secondRequest,
    );

    container.listen(provider, (_, _) {});
    container.listen(secondProvider, (_, _) {});

    await Future.wait([
      container.read(provider.future),
      container.read(secondProvider.future),
    ]);

    expect(repository.calls, containsAll([request, secondRequest]));
    expect(repository.calls, hasLength(2));
  });
}
