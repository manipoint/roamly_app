import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/data/models/canonical_location_model.dart';

void main() {
  Map<String, Object?> payload() => {
    'provider': ' Google ',
    'provider_location_id': 'lahore-id',
    'canonical_name': 'Lahore, Pakistan',
    'country_code': 'pk',
    'latitude': 31,
    'longitude': 74.3587,
  };

  test('normalizes and round trips a valid selected location', () {
    final model = CanonicalLocationModel.fromJson(payload());
    expect(model.toDomain().provider, 'google');
    expect(model.toDomain().countryCode, 'PK');
    expect(model.toDomain().latitude, 31.0);
    expect(
      CanonicalLocationModel.fromDomain(model.toDomain()).toJson(),
      model.toJson(),
    );
  });

  test('rejects invalid coordinates and incomplete locations', () {
    for (final value in <Object?>[null, '31', 91, double.nan]) {
      expect(
        () =>
            CanonicalLocationModel.fromJson({...payload(), 'latitude': value}),
        throwsFormatException,
      );
    }
    final missing = payload()..remove('provider_location_id');
    expect(
      () => CanonicalLocationModel.fromJson(missing),
      throwsFormatException,
    );
  });

  test('enforces location-specific string rules', () {
    for (final entry in {
      'provider': 'bad provider',
      'country_code': '12',
      'canonical_name': ' ',
    }.entries) {
      expect(
        () => CanonicalLocationModel.fromJson({
          ...payload(),
          entry.key: entry.value,
        }),
        throwsFormatException,
      );
    }
  });
}
