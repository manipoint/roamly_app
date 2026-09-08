import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/features/preferences/domain/failures/location_resolution_failure.dart';
import 'package:roamly_app/src/features/preferences/domain/policies/location_resolution_policy.dart';
import 'package:roamly_app/src/features/preferences/presentation/providers/preference_dependency_providers.dart';
import 'package:roamly_app/src/features/preferences/presentation/state/location_search_state.dart';

final locationSearchControllerProvider =
    NotifierProvider.autoDispose<LocationSearchController, LocationSearchState>(
      LocationSearchController.new,
    );

final class LocationSearchController extends Notifier<LocationSearchState> {
  static const Duration debounceDuration = Duration(milliseconds: 400);
  Timer? _debounceTimer;
  int _requestGeneration = 0;
  bool _isDisposed = false;
  @override
  LocationSearchState build() {
    _isDisposed = false;
    ref.onDispose(() {
      _isDisposed = true;
      _requestGeneration++;
      _debounceTimer?.cancel();
      _debounceTimer = null;
    });
    return const LocationSearchState.idle();
  }

  void search(String query) {
    final normalizedQuery = query.trim();
    if (normalizedQuery == state.query) {
      return;
    }
    _schedule(normalizedQuery);
  }

  void _schedule(String normalizedQuery) {
    _invalidatePendingWork();
    if (normalizedQuery.length < LocationResolutionPolicy.minimumQueryLength) {
      state = LocationSearchState.idle(query: normalizedQuery);
      return;
    }
    if (normalizedQuery.length > LocationResolutionPolicy.maximumQueryLength) {
      state = LocationSearchState.failure(
        query: normalizedQuery,
        failure: const LocationResolutionFailure.invalidQuery(),
      );
      return;
    }
    state = LocationSearchState.idle(query: normalizedQuery);
    final generation = _requestGeneration;
    _debounceTimer = Timer(debounceDuration, () {
      _debounceTimer = null;
      unawaited(_resolve(normalizedQuery, generation));
    });
  }

  void _invalidatePendingWork() {
    _requestGeneration++;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  Future<void> _resolve(String normalizedQuery, int generation) async {
    if (!_isCurrent(generation)) {
      return;
    }
    state = LocationSearchState.loading(query: normalizedQuery);
    final result = await ref
        .read(locationResolutionRepositoryProvider)
        .resolve(query: normalizedQuery);
    if (!_isCurrent(generation)) {
      return;
    }
    result.fold<void>(
      onSuccess: (options) {
        state = options.isEmpty
            ? LocationSearchState.empty(query: normalizedQuery)
            : LocationSearchState.success(
                query: normalizedQuery,
                options: options,
              );
      },
      onFailure: (failure) {
        state = LocationSearchState.failure(
          query: normalizedQuery,
          failure: failure,
        );
      },
    );
  }

  bool _isCurrent(int generation) {
    return !_isDisposed && generation == _requestGeneration;
  }

  void retry() {
    if (state.status != LocationSearchStatus.failure) {
      return;
    }
    _schedule(state.query);
  }

  void clear() {
    _invalidatePendingWork();
    state = const LocationSearchState.idle();
  }
}
