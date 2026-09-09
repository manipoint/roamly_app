import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/domain/entities/home_discovery.dart';
import 'package:roamly_app/src/features/home/domain/repositories/home_discovery_repository.dart';
import 'package:roamly_app/src/features/home/presentation/providers/home_dependency_providers.dart';
import 'package:roamly_core/roamly_core.dart';

final class _Repository implements HomeDiscoveryRepository {
  @override
  Future<Result<HomeDiscovery>> getHomeDiscovery({required int limit}) {
    throw UnsupportedError('No request is expected in this test.');
  }
}

void main() {
  test('fails fast when the composition root does not override it', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(homeDiscoveryRepositoryProvider),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
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
