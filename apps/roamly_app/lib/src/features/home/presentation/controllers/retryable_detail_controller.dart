import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/home_discovery_repository.dart';
import '../providers/home_dependency_providers.dart';
import '../support/successful_result_retention.dart';

/// Shared lifecycle for read-only detail requests.
///
/// It supports an initial load, explicit recovery from an error, stale-result
/// protection, and bounded retention after successful requests.
abstract base class RetryableDetailController<T> extends AsyncNotifier<T> {
  int _generation = 0;
  SuccessfulResultRetention? _retention;

  Duration get cacheDuration;

  Future<T> fetch(HomeDiscoveryRepository repository);

  @override
  Future<T> build() async {
    _generation++;

    final repository = ref.watch(homeDiscoveryRepositoryProvider);
    final detail = await fetch(repository);

    _retainSuccessfulResult();

    return detail;
  }

  /// Retries only a failed detail request and ignores concurrent work.
  Future<bool> retry() async {
    if (!ref.mounted || state.isLoading || !state.hasError) {
      return false;
    }

    final generation = ++_generation;
    final repository = ref.read(homeDiscoveryRepositoryProvider);

    state = AsyncLoading<T>();

    final nextState = await AsyncValue.guard<T>(() => fetch(repository));

    if (!ref.mounted || generation != _generation) {
      return false;
    }

    state = nextState;

    if (nextState.hasValue) {
      _retainSuccessfulResult();
    }

    return nextState.hasValue;
  }

  void _retainSuccessfulResult() {
    if (!ref.mounted) return;

    final retention = _retention ??= SuccessfulResultRetention(
      ref: ref,
      duration: cacheDuration,
    );
    retention.retain();
  }
}
