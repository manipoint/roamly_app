import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/data/models/destination_model.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';

Map<String, Object?> _json() => <String, Object?>{
  'id': 'A1B2C3D4-E5F6-47A8-90BC-D1E2F3A4B5C6',
  'slug': 'lahore-pakistan',
  'name': ' Lahore ',
  'country_name': 'Pakistan',
  'country_code': 'PK',
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

  test('prefers nested cover image over legacy image fields', () {
    final json = _json()
      ..['cover_image'] = <String, Object?>{
        'id': '00000000-0000-4000-8000-000000000099',
        'url': 'https://images.example.test/new-cover.webp',
        'alt_text': ' New cover description ',
        'caption': null,
        'width': null,
        'height': null,
      };
    final destination = DestinationModel.fromJson(json).toDomain();
    expect(
      destination.imageUri.toString(),
      'https://images.example.test/new-cover.webp',
    );
    expect(destination.imageAlt, 'New cover description');
  });

  test('rejects malformed cover images even when legacy fields are valid', () {
    final invalidCovers = <Object?>[
      null,
      'https://images.example.test/cover.webp',
      <Object?>[],
      <String, Object?>{},
      <String, Object?>{'url': 'https://images.example.test/cover.webp'},
      for (final url in [
        'http://images.example.test/cover.webp',
        '/cover.webp',
        'invalid',
      ])
        <String, Object?>{'url': url, 'alt_text': 'Cover'},
      <String, Object?>{
        'url': 'https://images.example.test/cover.webp',
        'alt_text': ' ',
      },
      <String, Object?>{
        'url': 'https://images.example.test/cover.webp',
        'alt_text': 42,
      },
    ];
    for (final cover in invalidCovers) {
      final json = _json()..['cover_image'] = cover;
      expect(() => DestinationModel.fromJson(json), throwsFormatException);
    }
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
      _json()..['country_code'] = 'pk',
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
