import 'package:roamly_core/roamly_core.dart';

import '../../../preferences/domain/entities/preference_types.dart';

/// Provider-independent destination content displayed on Home.
final class Destination {
  Destination({
    required this.id,
    required this.slug,
    required this.name,
    required this.countryName,
    required this.countryCode,
    required this.summary,
    required this.imageUri,
    required this.imageAlt,
    required this.latitude,
    required this.longitude,
    required this.budgetTier,
    required Iterable<TravelStyle> styles,
    required Iterable<TravelInterest> interests,
  }) : styles = Set<TravelStyle>.unmodifiable(styles),
       interests = Set<TravelInterest>.unmodifiable(interests);

  final String id;
  final String slug;
  final String name;
  final String countryName;
  final String countryCode;
  final String summary;
  final Uri imageUri;
  final String imageAlt;
  final double latitude;
  final double longitude;
  final BudgetTier budgetTier;
  final Set<TravelStyle> styles;
  final Set<TravelInterest> interests;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Destination &&
            id == other.id &&
            slug == other.slug &&
            name == other.name &&
            countryName == other.countryName &&
            countryCode == other.countryCode &&
            summary == other.summary &&
            imageUri == other.imageUri &&
            imageAlt == other.imageAlt &&
            latitude == other.latitude &&
            longitude == other.longitude &&
            budgetTier == other.budgetTier &&
            CollectionEquality.unordered(styles, other.styles) &&
            CollectionEquality.unordered(interests, other.interests);
  }

  @override
  int get hashCode => Object.hash(
    id,
    slug,
    name,
    countryName,
    countryCode,
    summary,
    imageUri,
    imageAlt,
    latitude,
    longitude,
    budgetTier,
    Object.hashAllUnordered(styles),
    Object.hashAllUnordered(interests),
  );
}
