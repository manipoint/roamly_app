import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_networking/roamly_networking.dart';

import '../../domain/entities/media_asset.dart';

final class MediaAssetModel {
  const MediaAssetModel._(this._mediaAsset);

  final MediaAsset _mediaAsset;

  factory MediaAssetModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);
    final id = reader.string(
      'id',
      trim: true,
      minLength: RoamlyValueValidators.uuidLength,
      maxLength: RoamlyValueValidators.uuidLength,
    );
    if (!RoamlyValueValidators.isValidUuid(id)) {
      throw const FormatException('Invalid media id.');
    }
    final width = reader.nullable<int>(
      'width',
      () => reader.integer('width', min: 1),
    );
    final height = reader.nullable<int>(
      'height',
      () => reader.integer('height', min: 1),
    );
    if ((width == null) != (height == null)) {
      throw const FormatException(
        'Media width and height must both be present or both be null.',
      );
    }
    return MediaAssetModel._(
      MediaAsset(
        id: id.toLowerCase(),
        uri: reader.uri('url', maxLength: 2048),
        altText: reader.string(
          'alt_text',
          trim: true,
          minLength: 2,
          maxLength: 200,
        ),
        caption: reader.nullable<String>(
          'caption',
          () => reader.string('caption', trim: true, maxLength: 500),
        ),
        width: width,
        height: height,
      ),
    );
  }

  MediaAsset toDomain() => _mediaAsset;
}
