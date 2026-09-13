import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/data/models/destination_detail_model.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_detail.dart';

Map<String, Object?> _media({
  String id = '00000000-0000-4000-8000-000000000010',
}) => <String, Object?>{
  'id': id,
  'url': 'https://images.example.test/bali.webp',
  'alt_text': 'Bali temple landscape',
  'caption': null,
  'width': 1200,
  'height': 800,
};

Map<String, Object?> _place() => <String, Object?>{
  'id': '00000000-0000-4000-8000-000000000020',
  'slug': 'tanah-lot',
  'name': 'Tanah Lot',
  'place_type': 'attraction',
  'summary': 'Visit Tanah Lot while exploring the Bali coastline.',
  'location': <String, Object?>{
    'latitude': -8.6212,
    'longitude': 115.0868,
    'map_zoom': null,
  },
  'address': null,
  'is_featured': true,
  'cover_image': _media(id: '00000000-0000-4000-8000-000000000021'),
};

Map<String, Object?> _payload() => <String, Object?>{
  'id': '10000000-0000-4000-8000-000000000006',
  'slug': 'bali-indonesia',
  'name': 'Bali',
  'destination_type': 'island',
  'country_name': 'Indonesia',
  'country_code': 'ID',
  'summary': 'Balance beaches, temples, rice terraces, and local communities.',
  'full_description':
      'Bali is an Indonesian island destination combining beaches, temples, rice landscapes, and local communities.',
  'location': <String, Object?>{
    'latitude': -8.4095,
    'longitude': 115.1889,
    'map_zoom': 9,
  },
  'budget_tier': 'mid_range',
  'styles': <Object?>['beaches', 'culture'],
  'interests': <Object?>['photography', 'local_culture'],
  'gallery': <Object?>[_media()],
  'places': <Object?>[_place()],
  'places_next_cursor': 'next-page',
  'has_more_places': true,
};

void main() {
  test('parses the complete destination detail contract', () {
    final detail = DestinationDetailModel.fromJson(_payload()).toDomain();

    expect(detail.id, '10000000-0000-4000-8000-000000000006');
    expect(detail.slug, 'bali-indonesia');
    expect(detail.type, DestinationType.island);
    expect(detail.countryCode, 'ID');
    expect(detail.location.mapZoom, 9);
    expect(detail.coverImage, detail.gallery.first);
    expect(detail.coverImage?.aspectRatio, 1.5);
    expect(detail.places.single.slug, 'tanah-lot');
    expect(detail.places.single.coverImage, isNotNull);
    expect(detail.hasMorePlaces, isTrue);
  });

  test('accepts empty media, null covers, and a completed place preview', () {
    final payload = _payload()
      ..['gallery'] = <Object?>[]
      ..['places_next_cursor'] = null
      ..['has_more_places'] = false;
    final place =
        (payload['places']! as List<Object?>).single as Map<String, Object?>;
    place['cover_image'] = null;

    final detail = DestinationDetailModel.fromJson(payload).toDomain();

    expect(detail.coverImage, isNull);
    expect(detail.places.single.coverImage, isNull);
    expect(detail.hasMorePlaces, isFalse);
  });

  test('rejects malformed destination identifiers and contract values', () {
    for (final entry in <MapEntry<String, Object?>>[
      const MapEntry('id', 'not-a-uuid'),
      const MapEntry('slug', 'Bali Indonesia'),
      const MapEntry('country_code', 'id'),
      const MapEntry('destination_type', 'planet'),
    ]) {
      expect(
        () => DestinationDetailModel.fromJson(
          _payload()..[entry.key] = entry.value,
        ),
        throwsFormatException,
        reason: entry.key,
      );
    }
  });

  test('rejects malformed nested media and place identifiers', () {
    final invalidMedia = _payload();
    ((invalidMedia['gallery']! as List<Object?>).single
            as Map<String, Object?>)['id'] =
        'invalid';

    final invalidPlaceId = _payload();
    ((invalidPlaceId['places']! as List<Object?>).single
            as Map<String, Object?>)['id'] =
        'invalid';

    final invalidPlaceSlug = _payload();
    ((invalidPlaceSlug['places']! as List<Object?>).single
            as Map<String, Object?>)['slug'] =
        'Tanah Lot';

    for (final payload in [invalidMedia, invalidPlaceId, invalidPlaceSlug]) {
      expect(
        () => DestinationDetailModel.fromJson(payload),
        throwsFormatException,
      );
    }
  });

  test('rejects inconsistent media dimensions and destination map zoom', () {
    final dimensions = _payload();
    ((dimensions['gallery']! as List<Object?>).single
            as Map<String, Object?>)['height'] =
        null;

    final zoom = _payload();
    (zoom['location']! as Map<String, Object?>)['map_zoom'] = null;

    expect(
      () => DestinationDetailModel.fromJson(dimensions),
      throwsFormatException,
    );
    expect(() => DestinationDetailModel.fromJson(zoom), throwsFormatException);
  });

  test('rejects duplicate gallery and place identities', () {
    final duplicateMedia = _payload();
    duplicateMedia['gallery'] = <Object?>[_media(), _media()];

    final duplicatePlaceId = _payload();
    duplicatePlaceId['places'] = <Object?>[_place(), _place()];

    final duplicatePlaceSlug = _payload();
    final secondPlace = _place()
      ..['id'] = '00000000-0000-4000-8000-000000000030';
    duplicatePlaceSlug['places'] = <Object?>[_place(), secondPlace];

    for (final payload in [
      duplicateMedia,
      duplicatePlaceId,
      duplicatePlaceSlug,
    ]) {
      expect(
        () => DestinationDetailModel.fromJson(payload),
        throwsFormatException,
      );
    }
  });

  test('rejects cursor and has-more disagreement', () {
    for (final payload in [
      _payload()
        ..['places_next_cursor'] = null
        ..['has_more_places'] = true,
      _payload()
        ..['places_next_cursor'] = 'next-page'
        ..['has_more_places'] = false,
    ]) {
      expect(
        () => DestinationDetailModel.fromJson(payload),
        throwsFormatException,
      );
    }
  });
}
