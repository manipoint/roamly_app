import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/data/models/assistant_rich_content_model.dart';

const _itineraryId = '00000000-0000-4000-8000-000000000004';

// Wire fields follow map-server/app/domain/assistant_content.py.
Map<String, Object?> _media() => {
  'url': 'https://images.example.com/kyoto.jpg',
  'alt_text': ' Kyoto temple ',
  'width': 1200,
  'height': 800,
};

Map<String, Object?> _place() => {
  'id': 'gion',
  'name': ' Gion ',
  'location': ' Kyoto ',
};

Map<String, Object?> _hotel() => {
  'id': 'hotel-1',
  'name': 'Kyoto Hotel',
  'location': 'Kyoto',
  'category': null,
};

Map<String, Object?> _summary() => {
  'title': 'Japan Adventure',
  'start_date': '2026-10-01',
  'end_date': '2026-10-03',
  'duration_days': 3,
  'cities': <String>[],
};

Map<String, Object?> _preview() => {
  'type': 'itinerary_preview',
  'id': 'generated-itinerary',
  'title': 'Your AI-Generated Itinerary',
  'itinerary_id': _itineraryId,
  'summary': _summary(),
  'days': <Object?>[],
};

Map<String, Object?> _carousel({bool hotel = false, int count = 1}) => {
  'type': hotel ? 'hotel_carousel' : 'place_carousel',
  'id': 'suggestions',
  'title': 'Suggested for you',
  'items': List.generate(count, (_) => hotel ? _hotel() : _place()),
};

Map<String, Object?> _rich(List<Object?> sections) => {
  'type': 'rich_response',
  'schema_version': 1,
  'sections': sections,
};

void main() {
  group('backend contract regressions', () {
    test('media reads the backend url field', () {
      final model = AssistantMediaModel.fromJson(_media());
      expect(model.uri, Uri.parse('https://images.example.com/kyoto.jpg'));
      expect(model.altText, 'Kyoto temple');
      expect(model.width, 1200);
      expect(model.height, 800);
    });

    test('preview accepts a section id distinct from itinerary_id', () {
      final model = AssistantItineraryPreviewModel.fromJson(_preview());
      expect(model.id, 'generated-itinerary');
      expect(model.itineraryId, _itineraryId);
    });

    test('summary accepts calendar dates without timezone or clock', () {
      final model = AssistantItinerarySummaryModel.fromJson(_summary());
      expect(model.startDate.year, 2026);
      expect(model.startDate.month, 10);
      expect(model.startDate.day, 1);
      expect(model.endDate.day, 3);
      expect(model.durationDays, 3);
    });

    test('day preview accepts a calendar date', () {
      final model = AssistantItineraryDayPreviewModel.fromJson({
        'day_number': 1,
        'date': '2026-10-01',
        'title': 'Arrival in Kyoto',
      });
      expect(model.date.day, 1);
      expect(model.dayNumber, 1);
      expect(model.subtitle, isNull);
    });

    test('cities come from list values rather than sibling JSON keys', () {
      // The conflicting sibling value must never replace the city name.
      final model = AssistantItinerarySummaryModel.fromJson({
        ..._summary(),
        'cities': ['Kyoto'],
        'Kyoto': 'Wrong city',
      });
      expect(model.cities, ['Kyoto']);
    });

    test('hotel accepts a serialized Decimal review score', () {
      final model = AssistantHotelCardModel.fromJson({
        ..._hotel(),
        'review_score': '9.4',
      });
      expect(model.reviewScore, 9.4);
    });

    test('hotel permits omitted optional category', () {
      final json = _hotel()..remove('category');
      expect(AssistantHotelCardModel.fromJson(json).category, isNull);
    });

    test('rich response parses an image-bearing place carousel', () {
      final model = AssistantRichContentModel.tryFromJson(
        _rich([
          {
            ..._carousel(),
            'items': [
              {..._place(), 'image': _media()},
            ],
          },
        ]),
      );
      final section = model!.sections.single as AssistantPlaceCarouselModel;
      expect(section.items.single.image, isNotNull);
    });
  });

  group('money validation', () {
    for (final entry in {
      'total': AssistantMoneyQualifier.total,
      'per_night': AssistantMoneyQualifier.perNight,
      'from': AssistantMoneyQualifier.from,
    }.entries) {
      test('preserves decimal precision and maps ${entry.key}', () {
        final model = AssistantMoneyModel.fromJson({
          'amount': '9007199254740993.01',
          'currency': 'USD',
          'qualifier': entry.key,
        });
        expect(model.amount, '9007199254740993.01');
        expect(model.currency, 'USD');
        expect(model.qualifier, entry.value);
      });
    }

    for (final amount in <Object?>[-1, '-1', 'NaN', '1,000', null]) {
      test('rejects invalid monetary amount $amount', () {
        expect(
          () => AssistantMoneyModel.fromJson({
            'amount': amount,
            'currency': 'USD',
            'qualifier': 'total',
          }),
          throwsFormatException,
        );
      });
    }
  });

  group('place validation', () {
    test('normalizes labels and permits absent optional fields', () {
      final model = AssistantPlaceCardModel.fromJson(_place());
      expect(model.id, 'gion');
      expect(model.name, 'Gion');
      expect(model.location, 'Kyoto');
      expect(model.image, isNull);
      expect(model.subtitle, isNull);
      expect(model.latitude, isNull);
      expect(model.longitude, isNull);
    });

    test('accepts zero coordinates and inclusive coordinate boundaries', () {
      for (final pair in [
        [0, 0],
        [-90, -180],
        [90, 180],
      ]) {
        final model = AssistantPlaceCardModel.fromJson({
          ..._place(),
          'latitude': pair[0],
          'longitude': pair[1],
        });
        expect(model.latitude, pair[0]);
        expect(model.longitude, pair[1]);
      }
    });

    for (final coordinates in <Map<String, Object?>>[
      {'latitude': 1},
      {'longitude': 1},
      {'latitude': 91, 'longitude': 0},
      {'latitude': 0, 'longitude': -181},
      {'latitude': double.nan, 'longitude': 0},
      {'latitude': '1', 'longitude': 0},
    ]) {
      test('rejects invalid coordinates $coordinates', () {
        expect(
          () => AssistantPlaceCardModel.fromJson({..._place(), ...coordinates}),
          throwsFormatException,
        );
      });
    }
  });

  group('versioning and collections', () {
    test('ignores unknown content types and future schema versions', () {
      expect(AssistantRichContentModel.tryFromJson({'type': 'future'}), isNull);
      expect(
        AssistantRichContentModel.tryFromJson({
          'type': 'rich_response',
          'schema_version': 2,
        }),
        isNull,
      );
    });

    test('skips unknown sections while preserving known section order', () {
      final model = AssistantRichContentModel.tryFromJson(
        _rich([
          _carousel(),
          {'type': 'future_section'},
          _carousel(hotel: true),
        ]),
      )!;
      expect(model.schemaVersion, 1);
      expect(model.sections, [
        isA<AssistantPlaceCarouselModel>(),
        isA<AssistantHotelCarouselModel>(),
      ]);
      expect(() => model.sections.clear(), throwsUnsupportedError);
    });

    for (final hotel in [false, true]) {
      test('carousel hotel=$hotel accepts five immutable items', () {
        final section = AssistantContentSectionModel.tryFromJson(
          _carousel(hotel: hotel, count: 5),
        );
        final List<Object?> items = switch (section) {
          AssistantPlaceCarouselModel(:final items) => items,
          AssistantHotelCarouselModel(:final items) => items,
          _ => throw StateError('Expected carousel'),
        };
        expect(items, hasLength(5));
        expect(() => items.clear(), throwsUnsupportedError);
      });
      for (final count in [0, 6]) {
        test('carousel hotel=$hotel rejects $count items', () {
          expect(
            () => AssistantContentSectionModel.tryFromJson(
              _carousel(hotel: hotel, count: count),
            ),
            throwsFormatException,
          );
        });
      }
    }

    test('rejects empty and oversized section arrays', () {
      for (final count in [0, 7]) {
        expect(
          () => AssistantRichContentModel.tryFromJson(
            _rich(List.generate(count, (_) => _carousel())),
          ),
          throwsFormatException,
        );
      }
    });

    test('malformed known sections are not silently treated as unknown', () {
      expect(
        () => AssistantRichContentModel.tryFromJson(
          _rich([
            {'type': 'place_carousel'},
          ]),
        ),
        throwsFormatException,
      );
    });
  });
}
