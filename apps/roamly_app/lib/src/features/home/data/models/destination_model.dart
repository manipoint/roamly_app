import 'package:roamly_app/src/app/validator/roamly_value_validators.dart';
import 'package:roamly_networking/roamly_networking.dart';

import '../../../preferences/data/mappers/preference_enum_mapper.dart';
import '../../../preferences/domain/entities/preference_types.dart';
import '../../domain/entities/destination.dart';
import 'media_asset_model.dart';

/// Strict transport representation of a Home destination card.
final class DestinationModel {
  const DestinationModel._(this._destination);

  final Destination _destination;

  factory DestinationModel.fromJson(Map<String, Object?> json) {
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

    // Prefer the current contract; only absent cover_image permits legacy data.
    final hasCoverImage = json.containsKey('cover_image');
    final coverImage = hasCoverImage
        ? MediaAssetModel.fromJson(reader.object('cover_image')).toDomain()
        : null;
    final imageUri =
        coverImage?.uri ??
        reader.uri(
          'image_url',
          allowedSchemes: const <String>{'https'},
          maxLength: 2048,
        );

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

    return DestinationModel._(
      Destination(
        id: id.toLowerCase(),
        slug: slug,
        name: reader.string('name', trim: true, minLength: 2, maxLength: 120),
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
        imageUri: imageUri,
        imageAlt:
            coverImage?.altText ??
            reader.string(
              'image_alt',
              trim: true,
              minLength: 2,
              maxLength: 200,
            ),
        latitude: reader.number('latitude', min: -90, max: 90),
        longitude: reader.number('longitude', min: -180, max: 180),
        budgetTier: PreferenceEnumMapper.budgetTierFromJson(
          reader.string('budget_tier'),
        ),
        styles: styles,
        interests: interests,
      ),
    );
  }
  Destination toDomain() => _destination;
}
