import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/data/models/destination_place_detail_model.dart';

String _uuid(int suffix) {
  return '00000000-0000-4000-8000-'
      '${suffix.toString().padLeft(12, '0')}';
}

Map<String, Object?> _media({
  int id = 3,
  String url = 'https://images.example.test/meiji-shrine.webp',
}) {
  return <String, Object?>{
    'id': _uuid(id),
    'url': url,
    'alt_text': 'Meiji Shrine in Tokyo',
    'caption': null,
    'width': 1600,
    'height': 900,
  };
}

Map<String, Object?> _payload() {
  return <String, Object?>{
    'id': _uuid(1),
    'slug': 'meiji-shrine',
    'name': 'Meiji Shrine',
    'place_type': 'religious_site',
    'summary': 'Visit a peaceful shrine surrounded by a large forest in Tokyo.',
    'location': <String, Object?>{
      'latitude': 35.6748,
      'longitude': 139.6996,
      'map_zoom': null,
    },
    'address': '1 Yoyogi Kamizonocho, Shibuya, Tokyo',
    'is_featured': true,
    'cover_image': _media(
      id: 2,
      url: 'https://images.example.test/meiji-cover.webp',
    ),
    'destination_slug': 'tokyo-japan',
    'full_description':
        'Meiji Shrine is a peaceful Shinto shrine surrounded by a forest '
        'in the centre of Tokyo.',
    'gallery': <Object?>[
      _media(id: 3),
      _media(id: 4, url: 'https://images.example.test/meiji-garden.webp'),
    ],
  };
}

void main() {
  test('parses the complete destination place detail response', () {
    final detail = DestinationPlaceDetailModel.fromJson(_payload()).toDomain();

    expect(detail.destinationSlug, 'tokyo-japan');
    expect(detail.place.id, _uuid(1));
    expect(detail.place.slug, 'meiji-shrine');
    expect(detail.place.name, 'Meiji Shrine');
    expect(detail.place.placeType, 'religious_site');
    expect(detail.place.address, '1 Yoyogi Kamizonocho, Shibuya, Tokyo');
    expect(detail.place.location.latitude, 35.6748);
    expect(detail.place.location.longitude, 139.6996);
    expect(detail.place.isFeatured, isTrue);
    expect(detail.gallery, hasLength(2));

    // Explicit cover_image has priority over gallery.
    expect(detail.coverImage?.id, _uuid(2));
  });

  test('uses first gallery image when explicit cover is absent', () {
    final payload = _payload()..['cover_image'] = null;

    final detail = DestinationPlaceDetailModel.fromJson(payload).toDomain();

    expect(detail.coverImage?.id, _uuid(3));
  });

  test('accepts an empty gallery and missing optional place values', () {
    final payload = _payload()
      ..['address'] = null
      ..['cover_image'] = null
      ..['gallery'] = <Object?>[];

    final detail = DestinationPlaceDetailModel.fromJson(payload).toDomain();

    expect(detail.place.address, isNull);
    expect(detail.gallery, isEmpty);
    expect(detail.coverImage, isNull);
  });

  test('creates an immutable gallery', () {
    final detail = DestinationPlaceDetailModel.fromJson(_payload()).toDomain();

    expect(() => detail.gallery.clear(), throwsUnsupportedError);
  });

  test('rejects an invalid destination slug', () {
    final payload = _payload()..['destination_slug'] = 'Tokyo Japan';

    expect(
      () => DestinationPlaceDetailModel.fromJson(payload),
      throwsFormatException,
    );
  });

  test('rejects malformed common place fields', () {
    final invalidId = _payload()..['id'] = 'invalid';
    final invalidPlaceSlug = _payload()..['slug'] = 'Meiji Shrine';
    final invalidLocation = _payload()
      ..['location'] = <String, Object?>{
        'latitude': 95,
        'longitude': 139.6996,
        'map_zoom': null,
      };

    for (final payload in [invalidId, invalidPlaceSlug, invalidLocation]) {
      expect(
        () => DestinationPlaceDetailModel.fromJson(payload),
        throwsFormatException,
      );
    }
  });

  test('rejects invalid full description bounds', () {
    final payload = _payload()..['full_description'] = 'Too short';

    expect(
      () => DestinationPlaceDetailModel.fromJson(payload),
      throwsFormatException,
    );
  });

  test('rejects duplicate gallery media', () {
    final media = _media(id: 3);
    final payload = _payload()..['gallery'] = <Object?>[media, media];

    expect(
      () => DestinationPlaceDetailModel.fromJson(payload),
      throwsFormatException,
    );
  });

  test('rejects a gallery larger than backend limit', () {
    final payload = _payload()
      ..['gallery'] = List<Object?>.generate(
        13,
        (index) => _media(
          id: index + 10,
          url: 'https://images.example.test/gallery-$index.webp',
        ),
      );

    expect(
      () => DestinationPlaceDetailModel.fromJson(payload),
      throwsFormatException,
    );
  });

  test('fromValue rejects a non-object response', () {
    expect(
      () => DestinationPlaceDetailModel.fromValue(<Object?>[]),
      throwsFormatException,
    );
  });
}
