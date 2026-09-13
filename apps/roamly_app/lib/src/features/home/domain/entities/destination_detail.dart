import 'package:roamly_core/roamly_core.dart';

import '../../../preferences/domain/entities/preference_types.dart';
import 'map_location.dart';
import 'media_asset.dart';

enum DestinationType { city, region, island, country }

final class DestinationPlacePreview {
  const DestinationPlacePreview({
    required this.id,
    required this.slug,
    required this.name,
    required this.placeType,
    required this.summary,
    required this.location,
    required this.address,
    required this.isFeatured,
    required this.coverImage,
  });

  final String id;
  final String slug;
  final String name;
  final String placeType;
  final String summary;
  final MapLocation location;
  final String? address;
  final bool isFeatured;
  final MediaAsset? coverImage;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DestinationPlacePreview &&
            id == other.id &&
            slug == other.slug &&
            name == other.name &&
            placeType == other.placeType &&
            summary == other.summary &&
            location == other.location &&
            address == other.address &&
            isFeatured == other.isFeatured &&
            coverImage == other.coverImage;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      slug,
      name,
      placeType,
      summary,
      location,
      address,
      isFeatured,
      coverImage,
    );
  }
}

final class DestinationDetail {
  DestinationDetail({
    required this.id,
    required this.slug,
    required this.name,
    required this.type,
    required this.countryName,
    required this.countryCode,
    required this.summary,
    required this.fullDescription,
    required this.location,
    required this.budgetTier,
    required Iterable<TravelStyle> styles,
    required Iterable<TravelInterest> interests,
    required Iterable<MediaAsset> gallery,
    required Iterable<DestinationPlacePreview> places,
    required this.placesNextCursor,
  }) : styles = Set<TravelStyle>.unmodifiable(styles),
       interests = Set<TravelInterest>.unmodifiable(interests),
       gallery = List<MediaAsset>.unmodifiable(gallery),
       places = List<DestinationPlacePreview>.unmodifiable(places);

  final String id;
  final String slug;
  final String name;
  final DestinationType type;
  final String countryName;
  final String countryCode;
  final String summary;
  final String fullDescription;
  final MapLocation location;
  final BudgetTier budgetTier;
  final Set<TravelStyle> styles;
  final Set<TravelInterest> interests;

  /// Ordered media. The backend places the cover first.
  final List<MediaAsset> gallery;

  /// First bounded page of curated places.
  final List<DestinationPlacePreview> places;

  final String? placesNextCursor;

  bool get hasMorePlaces => placesNextCursor != null;

  MediaAsset? get coverImage => gallery.isEmpty ? null : gallery.first;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DestinationDetail &&
            id == other.id &&
            slug == other.slug &&
            name == other.name &&
            type == other.type &&
            countryName == other.countryName &&
            countryCode == other.countryCode &&
            summary == other.summary &&
            fullDescription == other.fullDescription &&
            location == other.location &&
            budgetTier == other.budgetTier &&
            CollectionEquality.unordered(styles, other.styles) &&
            CollectionEquality.unordered(interests, other.interests) &&
            CollectionEquality.ordered(gallery, other.gallery) &&
            CollectionEquality.ordered(places, other.places) &&
            placesNextCursor == other.placesNextCursor;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      slug,
      name,
      type,
      countryName,
      countryCode,
      summary,
      fullDescription,
      location,
      budgetTier,
      Object.hashAllUnordered(styles),
      Object.hashAllUnordered(interests),
      Object.hashAll(gallery),
      Object.hashAll(places),
      placesNextCursor,
    );
  }
}
