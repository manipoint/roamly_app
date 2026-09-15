import 'package:roamly_app/src/features/home/domain/entities/destination_collection_query.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_detail.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_page.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_place_detail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/domain/entities/home_discovery.dart';
import 'package:roamly_app/src/features/home/domain/repositories/home_discovery_repository.dart';
import 'package:roamly_app/src/features/home/presentation/providers/home_dependency_providers.dart';
import 'package:roamly_core/roamly_core.dart';

final class _Repository implements HomeDiscoveryRepository {
  @override
  Future<Result<DestinationPage>> getDestinations({
    required DestinationCollectionQuery query,
    int limit = 20,
    String? cursor,
  }) => throw StateError('Unexpected catalogue request in Home-only test');

  @override
  Future<Result<HomeDiscovery>> getHome({required int limit}) {
    throw UnsupportedError('No request is expected in this test.');
  }

  @override
  Future<Result<DestinationDetail>> getDestinationDetail({
    required String slug,
  }) => throw StateError('Unexpected destination detail request');

  @override
  Future<Result<DestinationPlaceDetail>> getDestinationPlaceDetail({
    required String destinationSlug,
    required String placeSlug,
  }) => throw StateError('Unexpected destination place detail request');
}

void main() {
  test('fails fast when the composition root does not override it', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(homeDiscoveryRepositoryProvider),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('must be overridden by the application'),
        ),
      ),
    );
  });

  test('returns the repository supplied by the composition root', () {
    final repository = _Repository();
    final container = ProviderContainer(
      overrides: [
        homeDiscoveryRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(homeDiscoveryRepositoryProvider), same(repository));
  });
}
