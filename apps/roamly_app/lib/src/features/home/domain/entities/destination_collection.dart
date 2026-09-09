import 'package:roamly_core/roamly_core.dart';

import 'destination.dart';

enum DiscoveryCollectionKind { featured, trending }

/// Ranked Home collection whose item order has presentation meaning.
final class DestinationCollection {
  DestinationCollection({
    required this.kind,
    required Iterable<Destination> items,
  }) : items = List<Destination>.unmodifiable(items);

  final DiscoveryCollectionKind kind;
  final List<Destination> items;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DestinationCollection &&
            kind == other.kind &&
            CollectionEquality.ordered(items, other.items);
  }

  @override
  int get hashCode => Object.hash(kind, Object.hashAll(items));
}
