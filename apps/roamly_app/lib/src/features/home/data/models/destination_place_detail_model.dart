import 'package:roamly_app/src/app/validator/roamly_value_validators.dart';
import 'package:roamly_networking/roamly_networking.dart';

import '../../domain/entities/destination_place_detail.dart';
import '../../domain/entities/media_asset.dart';
import 'destination_place_preview_model.dart';
import 'media_asset_model.dart';

final class DestinationPlaceDetailModel {
  const DestinationPlaceDetailModel._(this._detail);

  static const int _maximumGallerySize = 12;

  final DestinationPlaceDetail _detail;

  factory DestinationPlaceDetailModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);

    final destinationSlug = reader.string(
      'destination_slug',
      trim: true,
      minLength: RoamlyValueValidators.minimumSlugLength,
      maxLength: RoamlyValueValidators.maximumSlugLength,
    );

    if (!RoamlyValueValidators.isValidSlug(destinationSlug)) {
      throw const FormatException('Invalid destination slug in place detail.');
    }

    final gallery = reader.list<MediaAsset>(
      'gallery',
      maxLength: _maximumGallerySize,
      parseItem: (value) {
        return MediaAssetModel.fromValue(value).toDomain();
      },
    );

    _ensureUniqueMedia(gallery);

    return DestinationPlaceDetailModel._(
      DestinationPlaceDetail(
        destinationSlug: destinationSlug,
        place: DestinationPlacePreviewModel.fromJson(json).toDomain(),
        fullDescription: reader.string(
          'full_description',
          trim: true,
          minLength: 20,
          maxLength: 5000,
        ),
        gallery: gallery,
      ),
    );
  }

  factory DestinationPlaceDetailModel.fromValue(Object? value) {
    final reader = JsonReader(<String, Object?>{
      'destination_place_detail': value,
    });

    return DestinationPlaceDetailModel.fromJson(
      reader.object('destination_place_detail'),
    );
  }

  DestinationPlaceDetail toDomain() => _detail;

  static void _ensureUniqueMedia(Iterable<MediaAsset> gallery) {
    final ids = gallery.map((media) => media.id).toList(growable: false);

    if (ids.toSet().length != ids.length) {
      throw const FormatException(
        'Destination place gallery contains duplicate media.',
      );
    }
  }
}
