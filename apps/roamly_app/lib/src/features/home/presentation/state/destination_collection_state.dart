import 'package:roamly_core/roamly_core.dart';

import '../../domain/entities/destination.dart';

final class DestinationCollectionState {
  DestinationCollectionState({
    required Iterable<Destination> items,
    required this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreFailure,
  }) : items = List<Destination>.unmodifiable(items);

  final List<Destination> items;
  final String? nextCursor;
  final bool isLoadingMore;
  final AppFailure? loadMoreFailure;

  bool get isEmpty => items.isEmpty;
  bool get hasMore => nextCursor != null;

  bool get canLoadMore => hasMore && !isLoadingMore && loadMoreFailure == null;

  bool get canRetryLoadMore =>
      hasMore && !isLoadingMore && loadMoreFailure != null;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DestinationCollectionState &&
            CollectionEquality.ordered(items, other.items) &&
            nextCursor == other.nextCursor &&
            isLoadingMore == other.isLoadingMore &&
            loadMoreFailure?.code == other.loadMoreFailure?.code;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(items),
    nextCursor,
    isLoadingMore,
    loadMoreFailure?.code,
  );
}
