import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_networking/roamly_networking.dart';

import '../../../preferences/data/mappers/preference_enum_mapper.dart';
import '../../../preferences/domain/entities/preference_types.dart';
import '../../domain/entities/destination_detail.dart';
import '../../domain/entities/media_asset.dart';
import '../mappers/destination_detail_enum_mapper.dart';
import 'destination_place_preview_model.dart';
import 'map_location_model.dart';
import 'media_asset_model.dart';

final class DestinationDetailModel {
  const DestinationDetailModel._(this._detail);

  static const int _maximumGallerySize = 12;
  static const int _maximumPlacePreviewSize = 10;
  static const int _maximumCursorLength = 512;

  final DestinationDetail _detail;

  factory DestinationDetailModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);
    final id = reader.string(
      'id',
      trim: true,
      minLength: RoamlyValueValidators.uuidLength,
      maxLength: RoamlyValueValidators.uuidLength,
    );
    if (!RoamlyValueValidators.isValidUuid(id)) {
      throw const FormatException('Invalid destination id.');
    }
    final slug = reader.string(
      'slug',
      trim: true,
      minLength: RoamlyValueValidators.minimumSlugLength,
      maxLength: RoamlyValueValidators.maximumSlugLength,
    );
    if (!RoamlyValueValidators.isValidSlug(slug)) {
      throw const FormatException('Invalid destination slug.');
    }
    final countryCode = reader.string(
      'country_code',
      trim: true,
      minLength: RoamlyValueValidators.countryCodeLength,
      maxLength: RoamlyValueValidators.countryCodeLength,
    );
    if (!RoamlyValueValidators.isValidCountryCode(countryCode)) {
      throw const FormatException('Invalid destination country code.');
    }
    final gallery = reader.objectList<MediaAsset>(
      'gallery',
      maxLength: _maximumGallerySize,
      parseItem: (json) => MediaAssetModel.fromJson(json).toDomain(),
    );
    final places = reader.objectList<DestinationPlacePreview>(
      'places',
      maxLength: _maximumPlacePreviewSize,
      parseItem: (json) =>
          DestinationPlacePreviewModel.fromJson(json).toDomain(),
    );
    _ensureUnique(gallery.map((media) => media.id), field: 'gallery ids');
    _ensureUnique(places.map((place) => place.id), field: 'place ids');
    _ensureUnique(places.map((place) => place.slug), field: 'place slugs');

    final placesNextCursor = reader.nullable<String>(
      'places_next_cursor',
      () => reader.string(
        'places_next_cursor',
        trim: true,
        minLength: 1,
        maxLength: _maximumCursorLength,
      ),
    );
    final hasMorePlaces = reader.boolean('has_more_places');
    if (hasMorePlaces != (placesNextCursor != null)) {
      throw const FormatException(
        'Place cursor and has_more_places are inconsistent.',
      );
    }
    final styles = reader.list<TravelStyle>(
      'styles',
      minLength: 1,
      maxLength: TravelStyle.values.length,
      unique: true,
      parseItem: PreferenceEnumMapper.travelStyleFromJson,
    );
    final interests = reader.list<TravelInterest>(
      'interests',
      minLength: 1,
      maxLength: TravelInterest.values.length,
      unique: true,
      parseItem: PreferenceEnumMapper.interestFromJson,
    );

    return DestinationDetailModel._(
      DestinationDetail(
        id: id.toLowerCase(),
        slug: slug,
        name: reader.string('name', trim: true, minLength: 2, maxLength: 120),
        type: DestinationDetailEnumMapper.destinationTypeFromJson(
          reader.string('destination_type'),
        ),
        countryName: reader.string(
          'country_name',
          trim: true,
          minLength: 2,
          maxLength: 120,
        ),
        countryCode: countryCode,
        summary: reader.string(
          'summary',
          trim: true,
          minLength: 20,
          maxLength: 600,
        ),
        fullDescription: reader.string(
          'full_description',
          trim: true,
          minLength: 20,
          maxLength: 5000,
        ),
        location: MapLocationModel.fromJson(
          reader.object('location'),
          requireMapZoom: true,
        ).toDomain(),
        budgetTier: PreferenceEnumMapper.budgetTierFromJson(
          reader.string('budget_tier'),
        ),
        styles: styles,
        interests: interests,
        gallery: gallery,
        places: places,
        placesNextCursor: placesNextCursor,
      ),
    );
  }

  DestinationDetail toDomain() => _detail;

  static void _ensureUnique(Iterable<String> values, {required String field}) {
    final items = values.toList(growable: false);
    if (items.toSet().length != items.length) {
      throw FormatException('$field contain duplicate values.');
    }
  }
}
