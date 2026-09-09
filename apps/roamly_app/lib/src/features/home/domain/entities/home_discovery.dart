import 'package:roamly_core/roamly_core.dart';

import 'destination.dart';
import 'destination_collection.dart';

/// Complete database-backed payload required by the Phase-1 Home screen.
final class HomeDiscovery {
  HomeDiscovery({
    required this.personalizationReady,
    required Iterable<Destination> suggested,
    required Iterable<Destination> popular,
    required this.spotlight,
  }) : suggested = List<Destination>.unmodifiable(suggested),
       popular = List<Destination>.unmodifiable(popular);

  final bool personalizationReady;
  final List<Destination> suggested;
  final List<Destination> popular;
  final DestinationCollection spotlight;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is HomeDiscovery &&
            personalizationReady == other.personalizationReady &&
            CollectionEquality.ordered(suggested, other.suggested) &&
            CollectionEquality.ordered(popular, other.popular) &&
            spotlight == other.spotlight;
  }

  @override
  int get hashCode => Object.hash(
    personalizationReady,
    Object.hashAll(suggested),
    Object.hashAll(popular),
    spotlight,
  );
}
