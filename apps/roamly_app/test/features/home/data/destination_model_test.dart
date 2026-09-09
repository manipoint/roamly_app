import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/data/models/destination_model.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';

Map<String, Object?> _json() => <String, Object?>{
  'id': 'A1B2C3D4-E5F6-47A8-90BC-D1E2F3A4B5C6',
  'slug': 'lahore-pakistan',
  'name': ' Lahore ',
  'country_name': 'Pakistan',
  'country_code': 'pk',
  'summary': 'Historic architecture and food culture.',
  'image_url': 'https://images.example.test/lahore.webp',
  'image_alt': 'Lahore Fort at sunset',
  'latitude': 31.5204,
  'longitude': 74.3587,
  'budget_tier': 'mid_range',
  'styles': <Object?>['culture', 'food'],
  'interests': <Object?>['history', 'local_culture'],
};

void main() {
  test('parses and normalizes a complete destination card', () {
    final destination = DestinationModel.fromJson(_json()).toDomain();

    expect(destination.id, 'a1b2c3d4-e5f6-47a8-90bc-d1e2f3a4b5c6');
    expect(destination.name, 'Lahore');
    expect(destination.countryCode, 'PK');
    expect(destination.imageUri.scheme, 'https');
    expect(destination.budgetTier, BudgetTier.midRange);
    expect(destination.styles, const <TravelStyle>{
      TravelStyle.culture,
      TravelStyle.food,
    });
    expect(destination.interests, const <TravelInterest>{
      TravelInterest.history,
      TravelInterest.localCulture,
    });
  });

  test('rejects duplicate taxonomy values through JsonReader', () {
    final json = _json()..['styles'] = <Object?>['culture', 'culture'];

    expect(() => DestinationModel.fromJson(json), throwsFormatException);
  });

  test('rejects insecure, relative, and malformed image URLs', () {
    for (final imageUrl in <String>[
      'http://images.example.test/lahore.webp',
      '/lahore.webp',
      'not a URL',
    ]) {
      final json = _json()..['image_url'] = imageUrl;
      expect(() => DestinationModel.fromJson(json), throwsFormatException);
    }
  });

  test('rejects invalid identifiers, coordinates, and enum values', () {
    final invalidCases = <Map<String, Object?>>[
      _json()..['id'] = 'not-a-uuid',
      _json()..['slug'] = 'Lahore Pakistan',
      _json()..['latitude'] = 91,
      _json()..['longitude'] = -181,
      _json()..['budget_tier'] = 'cheap',
      _json()..['interests'] = <Object?>[],
    ];

    for (final json in invalidCases) {
      expect(() => DestinationModel.fromJson(json), throwsFormatException);
    }
  });
}
