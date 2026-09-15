import 'package:roamly_core/roamly_core.dart';

import 'destination_detail.dart';
import 'media_asset.dart';

final class DestinationPlaceDetail {
  DestinationPlaceDetail({
    required this.destinationSlug,
    required this.place,
    required this.fullDescription,
    required Iterable<MediaAsset> gallery,
  }) : gallery = List<MediaAsset>.unmodifiable(gallery);

  final String destinationSlug;
  final DestinationPlacePreview place;
  final String fullDescription;
  final List<MediaAsset> gallery;
  MediaAsset? get coverImage {
    return place.coverImage ?? (gallery.isEmpty ? null : gallery.first);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DestinationPlaceDetail &&
            destinationSlug == other.destinationSlug &&
            place == other.place &&
            fullDescription == other.fullDescription &&
            CollectionEquality.ordered(gallery, other.gallery);
  }

  @override
  int get hashCode {
    return Object.hash(
      destinationSlug,
      place,
      fullDescription,
      Object.hashAll(gallery),
    );
  }
}
