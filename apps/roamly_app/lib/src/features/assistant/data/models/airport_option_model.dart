import 'package:roamly_networking/roamly_networking.dart';

import '../../../../app/validator/roamly_value_validators.dart';

enum AirportLocationType { airport, city }

final class AirportOptionModel {
  final String providerLocationId;
  final String iataCode;
  final AirportLocationType locationType;
  final String name;
  final String? cityName;
  final String? countryName;
  final String countryCode;

  const AirportOptionModel._({
    required this.providerLocationId,
    required this.iataCode,
    required this.locationType,
    required this.name,
    required this.cityName,
    required this.countryName,
    required this.countryCode,
  });

  factory AirportOptionModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);
    final providerLocationId = reader.string(
      'provider_location_id',
      trim: true,
      minLength: 1,
      maxLength: 256,
    );
    final iataCode = reader.string(
      'iata_code',
      trim: true,
      minLength: RoamlyValueValidators.iataCodeLength,
      maxLength: RoamlyValueValidators.iataCodeLength,
    );
    if (!RoamlyValueValidators.isValidIataCode(iataCode)) {
      throw const FormatException('Invalid IATA code.');
    }
    final rawLocationType = reader.string(
      'location_type',
      trim: true,
      minLength: 1,
    );
    final locationType = switch (rawLocationType) {
      'airport' => AirportLocationType.airport,
      'cite' => AirportLocationType.city,
      _ => throw const FormatException('Invalid airport location type.'),
    };
    final name = reader.string(
      'name',
      trim: true,
      minLength: 1,
      maxLength: 200,
    );
    final cityName = reader.nullable<String>(
      'city_name',
      () =>
          reader.string('city_name', trim: true, minLength: 1, maxLength: 120),
    );
    final countryName = reader.nullable<String>(
      'country_name',
      () => reader.string(
        'country_name',
        trim: true,
        minLength: 1,
        maxLength: 120,
      ),
    );
    final countryCode = reader.string(
      'country_code',
      trim: true,
      minLength: RoamlyValueValidators.countryCodeLength,
      maxLength: RoamlyValueValidators.countryCodeLength,
    );
    if (!RoamlyValueValidators.isValidCountryCode(countryCode)) {
      throw const FormatException('Invalid airport country code.');
    }
    return AirportOptionModel._(
      providerLocationId: providerLocationId,
      iataCode: iataCode,
      locationType: locationType,
      name: name,
      cityName: cityName,
      countryName: countryName,
      countryCode: countryCode,
    );
  }
}
