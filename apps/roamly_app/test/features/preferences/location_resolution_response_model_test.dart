import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/data/models/location_resolution_response_model.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/canonical_location.dart';

Map<String, Object?> _location({
  String id = 'ChIJ-example',
  String name = 'Lahore, Punjab, Pakistan',
}) {
  return <String, Object?>{
    'provider': 'google',
    'provider_location_id': id,
    'canonical_name': name,
    'country_code': 'PK',
    'latitude': 31.5204,
    'longitude': 74.3587,
  };
}

void main() {
  test('parses a bounded canonical location response', () {
    final model = LocationResolutionResponseModel.fromJson(<String, Object?>{
      'query': ' Lahore ',
      'options': <Object?>[_location()],
    });

    expect(model.query, 'Lahore');
    expect(model.options, hasLength(1));
    expect(
      model.options.single,
      const CanonicalLocation(
        provider: 'google',
        providerLocationId: 'ChIJ-example',
        canonicalName: 'Lahore, Punjab, Pakistan',
        countryCode: 'PK',
        latitude: 31.5204,
        longitude: 74.3587,
      ),
    );
  });

  test('accepts an empty provider result', () {
    final model = LocationResolutionResponseModel.fromJson(
      const <String, Object?>{'query': 'Unknown place', 'options': <Object?>[]},
    );

    expect(model.options, isEmpty);
  });

  test('exposes an immutable options list', () {
    final model = LocationResolutionResponseModel.fromJson(<String, Object?>{
      'query': 'Lahore',
      'options': <Object?>[_location()],
    });

    expect(
      () => model.options.add(model.options.single),
      throwsUnsupportedError,
    );
  });

  test('rejects more than five options', () {
    expect(
      () => LocationResolutionResponseModel.fromJson(<String, Object?>{
        'query': 'London',
        'options': List<Object?>.generate(
          6,
          (index) => _location(id: 'place-$index'),
        ),
      }),
      throwsFormatException,
    );
  });

  test('rejects malformed response fields and option items', () {
    final invalidResponses = <Map<String, Object?>>[
      const <String, Object?>{'options': <Object?>[]},
      const <String, Object?>{'query': 'L', 'options': <Object?>[]},
      const <String, Object?>{'query': 'Lahore', 'options': 'not-a-list'},
      const <String, Object?>{
        'query': 'Lahore',
        'options': <Object?>['not-an-object'],
      },
      const <String, Object?>{
        'query': 'Lahore',
        'options': <Object?>[
          <String, Object?>{
            'provider': 'google',
            'provider_location_id': 'place-id',
            'canonical_name': 'Lahore, Pakistan',
            'country_code': 'PK',
            'latitude': 200,
            'longitude': 74.3587,
          },
        ],
      },
    ];

    for (final response in invalidResponses) {
      expect(
        () => LocationResolutionResponseModel.fromJson(response),
        throwsFormatException,
      );
    }
  });
}
