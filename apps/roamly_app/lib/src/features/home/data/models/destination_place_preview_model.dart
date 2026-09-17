import 'package:roamly_app/src/app/validator/roamly_value_validators.dart';
import 'package:roamly_networking/roamly_networking.dart';

import '../../domain/entities/destination_detail.dart';
import '../../domain/entities/media_asset.dart';
import 'map_location_model.dart';
import 'media_asset_model.dart';

final class DestinationPlacePreviewModel {
  const DestinationPlacePreviewModel._(this._place);

  final DestinationPlacePreview _place;

  factory DestinationPlacePreviewModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);
    final id = reader.string(
      'id',
      trim: true,
      minLength: RoamlyValueValidators.uuidLength,
      maxLength: RoamlyValueValidators.uuidLength,
    );
    if (!RoamlyValueValidators.isValidUuid(id)) {
      throw const FormatException('Invalid destination place id.');
    }
    final slug = reader.string(
      'slug',
      trim: true,
      minLength: RoamlyValueValidators.minimumSlugLength,
      maxLength: RoamlyValueValidators.maximumSlugLength,
    );
    if (!RoamlyValueValidators.isValidSlug(slug)) {
      throw const FormatException('Invalid destination place slug.');
    }
    final coverImage = reader.nullable<MediaAsset>(
      'cover_image',
      () => MediaAssetModel.fromJson(reader.object('cover_image')).toDomain(),
    );
    return DestinationPlacePreviewModel._(
      DestinationPlacePreview(
        id: id.toLowerCase(),
        slug: slug,
        name: reader.string('name', trim: true, minLength: 1, maxLength: 160),
        placeType: reader.string(
          'place_type',
          trim: true,
          minLength: 1,
          maxLength: 50,
        ),
        summary: reader.string(
          'summary',
          trim: true,
          minLength: 20,
          maxLength: 600,
        ),
        location: MapLocationModel.fromJson(
          reader.object('location'),
        ).toDomain(),
        address: reader.nullable<String>(
          'address',
          () => reader.string('address', trim: true, maxLength: 300),
        ),
        isFeatured: reader.boolean('is_featured'),
        coverImage: coverImage,
      ),
    );
  }

  DestinationPlacePreview toDomain() => _place;
}
