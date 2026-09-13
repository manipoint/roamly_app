import 'package:roamly_core/roamly_core.dart';

import 'destination.dart';
final class DestinationPage {
  DestinationPage({
    required Iterable<Destination> items,
    required this.nextCursor,
  }) : items = List<Destination>.unmodifiable(items);

  final List<Destination> items;

  /// Opaque backend cursor. Null means pagination is complete.
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DestinationPage &&
            CollectionEquality.ordered(items, other.items) &&
            nextCursor == other.nextCursor;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(items), nextCursor);
}
