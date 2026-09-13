import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/home_discovery.dart';
import '../../domain/policies/home_discovery_policy.dart';
import '../../domain/repositories/home_discovery_repository.dart';
import '../providers/home_dependency_providers.dart';

/// Lazily loads the authenticated user's database-backed Home discovery.
///
/// The first request runs only when presentation watches this provider.
/// Automatic retry is disabled to prevent duplicate requests.
final homeDiscoveryControllerProvider =
    AsyncNotifierProvider.autoDispose<HomeDiscoveryController, HomeDiscovery>(
      HomeDiscoveryController.new,
      retry: (_, _) => null,
    );

final class HomeDiscoveryController extends AsyncNotifier<HomeDiscovery> {
  int _generation = 0;
  @override
  Future<HomeDiscovery> build() {
    _generation++;
    final repository = ref.watch(homeDiscoveryRepositoryProvider);

    return _fetch(repository);
  }

  /// Performs an explicit user-requested refresh.
  ///
  /// Returns false without another request when a load is already running.
  Future<bool> reload() async {
    if (!ref.mounted || state.isLoading) {
      return false;
    }
    final generation = _generation;
    final repository = ref.read(homeDiscoveryRepositoryProvider);
    state = const AsyncLoading<HomeDiscovery>();
    final nextState = await AsyncValue.guard<HomeDiscovery>(() => _fetch(repository));
    if (!ref.mounted || generation != _generation) {
      return false;
    }
    state = nextState;
    return !state.hasError;
  }

  static Future<HomeDiscovery> _fetch(
    HomeDiscoveryRepository repository,
  ) async {
    final result = await repository.getHome(
      limit: HomeDiscoveryPolicy.defaultSectionLimit,
    );

    return result.fold(
      onSuccess: (discovery) => discovery,
      onFailure: (failure) => throw failure,
    );
  }
}
