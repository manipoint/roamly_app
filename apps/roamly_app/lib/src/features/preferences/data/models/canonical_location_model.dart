import 'package:roamly_networking/roamly_networking.dart';

import '../../domain/entities/canonical_location.dart';

/// Validated transport representation of a selected location.
final class CanonicalLocationModel {
  const CanonicalLocationModel._(this._location);

  final CanonicalLocation _location;

  factory CanonicalLocationModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);
    final provider = reader
        .string('provider', trim: true, minLength: 1, maxLength: 32)
        .toLowerCase();
    final countryCode = reader
        .string('country_code', trim: true, minLength: 2, maxLength: 2)
        .toUpperCase();
    if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(provider)) {
      throw const FormatException('Invalid location provider.');
    }
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(countryCode)) {
      throw const FormatException('Invalid location country_code.');
    }
    return CanonicalLocationModel._(
      CanonicalLocation(
        provider: provider,
        providerLocationId: reader.string(
          'provider_location_id',
          trim: true,
          minLength: 1,
          maxLength: 256,
        ),
        canonicalName: reader.string(
          'canonical_name',
          trim: true,
          minLength: 2,
          maxLength: 200,
        ),
        countryCode: countryCode,
        latitude: reader.number('latitude', min: -90, max: 90),
        longitude: reader.number('longitude', min: -180, max: 180),
      ),
    );
  }

  /// Validates outgoing values using the same transport rules.
  factory CanonicalLocationModel.fromDomain(CanonicalLocation location) {
    return CanonicalLocationModel.fromJson({
      'provider': location.provider,
      'provider_location_id': location.providerLocationId,
      'canonical_name': location.canonicalName,
      'country_code': location.countryCode,
      'latitude': location.latitude,
      'longitude': location.longitude,
    });
  }

  CanonicalLocation toDomain() => _location;

  Map<String, Object?> toJson() => {
    'provider': _location.provider,
    'provider_location_id': _location.providerLocationId,
    'canonical_name': _location.canonicalName,
    'country_code': _location.countryCode,
    'latitude': _location.latitude,
    'longitude': _location.longitude,
  };
}
