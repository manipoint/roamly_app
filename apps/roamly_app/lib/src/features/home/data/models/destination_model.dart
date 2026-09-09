import 'package:roamly_networking/roamly_networking.dart';

import '../../../preferences/data/mappers/preference_enum_mapper.dart';
import '../../../preferences/domain/entities/preference_types.dart';
import '../../domain/entities/destination.dart';

/// Strict transport representation of a Home destination card.
final class DestinationModel {
  const DestinationModel._(this._destination);

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-'
    r'[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{12}$',
  );

  static final RegExp _slugPattern = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');

  static final RegExp _countryCodePattern = RegExp(r'^[A-Z]{2}$');

  final Destination _destination;

  factory DestinationModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);

    final id = reader.string('id', trim: true, minLength: 36, maxLength: 36);

    if (!_uuidPattern.hasMatch(id)) {
      throw const FormatException('Invalid destination id.');
    }

    final slug = reader.string(
      'slug',
      trim: true,
      minLength: 1,
      maxLength: 120,
    );

    if (!_slugPattern.hasMatch(slug)) {
      throw const FormatException('Invalid destination slug.');
    }

    final countryCode = reader
        .string('country_code', trim: true, minLength: 2, maxLength: 2)
        .toUpperCase();

    if (!_countryCodePattern.hasMatch(countryCode)) {
      throw const FormatException('Invalid destination country code.');
    }

    final imageUri = reader.uri(
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
        name: reader.string('name', trim: true, minLength: 1, maxLength: 120),
        countryName: reader.string(
          'country_name',
          trim: true,
          minLength: 1,
          maxLength: 120,
        ),
        countryCode: countryCode,
        summary: reader.string(
          'summary',
          trim: true,
          minLength: 1,
          maxLength: 500,
        ),
        imageUri: imageUri,
        imageAlt: reader.string(
          'image_alt',
          trim: true,
          minLength: 1,
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
  factory DestinationModel.fromValue(Object? value) {
    final reader = JsonReader(<String, Object?>{'destination': value});

    return DestinationModel.fromJson(reader.object('destination'));
  }

  Destination toDomain() => _destination;
}
