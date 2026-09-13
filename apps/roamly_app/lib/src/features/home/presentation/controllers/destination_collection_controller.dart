import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:roamly_core/roamly_core.dart';

import '../../domain/entities/destination.dart';
import '../../domain/entities/destination_collection_query.dart';
import '../../domain/entities/destination_page.dart';
import '../../domain/failures/destination_catalogue_failure.dart';
import '../../domain/repositories/home_discovery_repository.dart';
import '../providers/home_dependency_providers.dart';
import '../state/destination_collection_state.dart';

final destinationCollectionControllerProvider = AsyncNotifierProvider
    .autoDispose
    .family<
      DestinationCollectionController,
      DestinationCollectionState,
      DestinationCollectionQuery
    >(DestinationCollectionController.new, retry: (_, _) => null);

final class DestinationCollectionController
    extends AsyncNotifier<DestinationCollectionState> {
  DestinationCollectionController(this.query);

  static const int _pageSize = 20;
  static const Duration _cacheDuration = Duration(minutes: 5);

  final DestinationCollectionQuery query;

  int _generation = 0;
  bool _isRefreshing = false;

  KeepAliveLink? _cacheLink;
  Timer? _cacheTimer;

  @override
  Future<DestinationCollectionState> build() async {
    _generation++;

    ref.onDispose(() {
      _cacheTimer?.cancel();
      _cacheTimer = null;
      _cacheLink = null;
    });

    final repository = ref.watch(homeDiscoveryRepositoryProvider);
    final collection = await _firstPage(repository);

    _retainSuccessfulState();

    return collection;
  }

  /// Refreshes page one while retaining currently visible cards.
  Future<bool> reload() async {
    if (!ref.mounted || state.isLoading || _isRefreshing) {
      return false;
    }

    final current = state.asData?.value;
    final generation = ++_generation;
    final repository = ref.read(homeDiscoveryRepositoryProvider);

    // Initial-error retry has no previous cards to display.
    if (current == null) {
      state = const AsyncLoading<DestinationCollectionState>();

      final next = await AsyncValue.guard<DestinationCollectionState>(
        () => _firstPage(repository),
      );

      if (!_isCurrent(generation)) return false;

      state = next;

      if (next.hasValue) {
        _retainSuccessfulState();
      }

      return !next.hasError;
    }

    _isRefreshing = true;

    // Refresh supersedes load-more and clears its footer failure.
    final retained = DestinationCollectionState(
      items: current.items,
      nextCursor: current.nextCursor,
    );

    if (retained != current) {
      state = AsyncData(retained);
    }

    try {
      final refreshed = await _firstPage(repository);

      if (!_isCurrent(generation)) return false;

      // Avoid notifying Riverpod when API returned identical content.
      if (refreshed != retained) {
        state = AsyncData(refreshed);
      }

      _retainSuccessfulState();
      return true;
    } on AppFailure {
      // Existing cards remain visible.
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<bool> loadMore() => _loadMore(retry: false);

  Future<bool> retryLoadMore() => _loadMore(retry: true);

  Future<bool> _loadMore({required bool retry}) async {
    if (!ref.mounted || state.isLoading || state.hasError || _isRefreshing) {
      return false;
    }

    final current = state.asData?.value;
    if (current == null) return false;

    final allowed = retry ? current.canRetryLoadMore : current.canLoadMore;

    if (!allowed) return false;

    final cursor = current.nextCursor!;
    final generation = _generation;
    final repository = ref.read(homeDiscoveryRepositoryProvider);

    state = AsyncData(
      DestinationCollectionState(
        items: current.items,
        nextCursor: cursor,
        isLoadingMore: true,
      ),
    );

    try {
      final page = await _fetch(repository, cursor: cursor);

      if (!_isCurrent(generation)) return false;

      if (page.nextCursor == cursor) {
        _showLoadMoreFailure(
          current,
          const DestinationCatalogueFailure.invalidResponse(),
        );
        return false;
      }

      final updated = DestinationCollectionState(
        items: _appendUnique(current.items, page.items),
        nextCursor: page.nextCursor,
      );

      state = AsyncData(updated);
      _retainSuccessfulState();

      return true;
    } on AppFailure catch (failure) {
      if (!_isCurrent(generation)) return false;

      if (failure is DestinationCatalogueFailure &&
          failure.kind == DestinationCatalogueFailureKind.invalidCursor) {
        return reload();
      }

      _showLoadMoreFailure(current, failure);
      return false;
    } catch (_) {
      if (_isCurrent(generation)) {
        state = AsyncData(current);
      }
      rethrow;
    }
  }

  Future<DestinationCollectionState> _firstPage(
    HomeDiscoveryRepository repository,
  ) async {
    final page = await _fetch(repository);

    return DestinationCollectionState(
      items: page.items,
      nextCursor: page.nextCursor,
    );
  }

  Future<DestinationPage> _fetch(
    HomeDiscoveryRepository repository, {
    String? cursor,
  }) async {
    final result = await repository.getDestinations(
      query: query,
      limit: _pageSize,
      cursor: cursor,
    );

    return result.fold(
      onSuccess: (page) => page,
      onFailure: (failure) => throw failure,
    );
  }

  void _retainSuccessfulState() {
    if (!ref.mounted) return;

    _cacheLink ??= ref.keepAlive();

    _cacheTimer?.cancel();
    _cacheTimer = Timer(_cacheDuration, () {
      _cacheLink?.close();
      _cacheLink = null;
      _cacheTimer = null;
    });
  }

  bool _isCurrent(int generation) {
    return ref.mounted && generation == _generation;
  }

  void _showLoadMoreFailure(
    DestinationCollectionState current,
    AppFailure failure,
  ) {
    state = AsyncData(
      DestinationCollectionState(
        items: current.items,
        nextCursor: current.nextCursor,
        loadMoreFailure: failure,
      ),
    );
  }

  static List<Destination> _appendUnique(
    List<Destination> existing,
    List<Destination> incoming,
  ) {
    final ids = existing.map((item) => item.id).toSet();

    return [
      ...existing,
      for (final item in incoming)
        if (ids.add(item.id)) item,
    ];
  }
}
