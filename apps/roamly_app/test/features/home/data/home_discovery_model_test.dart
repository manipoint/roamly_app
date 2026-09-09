import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/data/models/destination_collection_model.dart';
import 'package:roamly_app/src/features/home/data/models/home_discovery_model.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_collection.dart';

Map<String, Object?> _destination(int index) => <String, Object?>{
  'id': '00000000-0000-4000-8000-${index.toRadixString(16).padLeft(12, '0')}',
  'slug': 'destination-$index',
  'name': 'Destination $index',
  'country_name': 'Pakistan',
  'country_code': 'PK',
  'summary': 'Curated destination number $index.',
  'image_url': 'https://images.example.test/destination-$index.webp',
  'image_alt': 'Destination $index landscape',
  'latitude': 30 + index / 100,
  'longitude': 70 + index / 100,
  'budget_tier': 'mid_range',
  'styles': <Object?>['culture'],
  'interests': <Object?>['history'],
};

Map<String, Object?> _response() => <String, Object?>{
  'personalization_ready': true,
  'suggested': <Object?>[_destination(1)],
  'popular': <Object?>[_destination(2)],
  'spotlight': <String, Object?>{
    'kind': 'featured',
    'items': <Object?>[_destination(3)],
  },
};

void main() {
  group('DestinationCollectionModel', () {
    test('maps its kind and preserves ranked destination order', () {
      final collection = DestinationCollectionModel.fromJson(<String, Object?>{
        'kind': 'trending',
        'items': <Object?>[_destination(2), _destination(1)],
      }).toDomain();

      expect(collection.kind, DiscoveryCollectionKind.trending);
      expect(collection.items.map((destination) => destination.id), <String>[
        '00000000-0000-4000-8000-000000000002',
        '00000000-0000-4000-8000-000000000001',
      ]);
    });

    test('allows an empty collection', () {
      final collection = DestinationCollectionModel.fromJson(<String, Object?>{
        'kind': 'featured',
        'items': <Object?>[],
      }).toDomain();

      expect(collection.items, isEmpty);
    });

    test(
      'rejects invalid kinds, malformed items, duplicates, and overflow',
      () {
        final duplicate = _destination(1);
        final invalidCases = <Map<String, Object?>>[
          <String, Object?>{'kind': 'popular', 'items': <Object?>[]},
          <String, Object?>{
            'kind': 'featured',
            'items': <Object?>['invalid'],
          },
          <String, Object?>{
            'kind': 'featured',
            'items': <Object?>[duplicate, duplicate],
          },
          <String, Object?>{
            'kind': 'featured',
            'items': List<Object?>.generate(7, _destination),
          },
        ];

        for (final json in invalidCases) {
          expect(
            () => DestinationCollectionModel.fromJson(json),
            throwsFormatException,
          );
        }
      },
    );
  });

  group('HomeDiscoveryModel', () {
    test('maps every bounded Home section', () {
      final discovery = HomeDiscoveryModel.fromJson(_response()).toDomain();

      expect(discovery.personalizationReady, isTrue);
      expect(discovery.suggested.single.name, 'Destination 1');
      expect(discovery.popular.single.name, 'Destination 2');
      expect(discovery.spotlight.kind, DiscoveryCollectionKind.featured);
      expect(discovery.spotlight.items.single.name, 'Destination 3');
    });

    test('allows empty server-ranked sections', () {
      final discovery = HomeDiscoveryModel.fromJson(<String, Object?>{
        'personalization_ready': false,
        'suggested': <Object?>[],
        'popular': <Object?>[],
        'spotlight': <String, Object?>{
          'kind': 'featured',
          'items': <Object?>[],
        },
      }).toDomain();

      expect(discovery.personalizationReady, isFalse);
      expect(discovery.suggested, isEmpty);
      expect(discovery.popular, isEmpty);
      expect(discovery.spotlight.items, isEmpty);
    });

    test('rejects missing, mistyped, duplicate, and oversized sections', () {
      final duplicate = _destination(1);
      final missingPopular = _response()..remove('popular');
      final invalidCases = <Map<String, Object?>>[
        missingPopular,
        _response()..['personalization_ready'] = 'true',
        _response()..['suggested'] = <Object?>[duplicate, duplicate],
        _response()..['popular'] = List<Object?>.generate(7, _destination),
        _response()..['spotlight'] = <String, Object?>{'kind': 'featured'},
      ];

      for (final json in invalidCases) {
        expect(() => HomeDiscoveryModel.fromJson(json), throwsFormatException);
      }
    });
  });
}
