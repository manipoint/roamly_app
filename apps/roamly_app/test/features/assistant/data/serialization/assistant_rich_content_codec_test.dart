import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/data/serialization/assistant_rich_content_codec.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_content_types.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_rich_content.dart';

import '../../fixtures/assistant_rich_content_fixture.dart';

void main() {
  const codec = AssistantRichContentCodec();

  test('round-trips all sections and nested fields with value equality', () {
    final original = richContentFixture();
    final encoded = codec.encode(original);
    expect(encoded, isNotNull);
    final restored = codec.decode(encoded);
    expect(restored, original);
    expect(restored.hashCode, original.hashCode);
    expect(identical(restored, original), isFalse);
  });

  test('preserves all qualifiers and nullable itinerary paces', () {
    for (final qualifier in AssistantMoneyQualifier.values) {
      for (final pace in [null, ...AssistantItineraryPace.values]) {
        final original = richContentFixture(qualifier: qualifier, pace: pace);
        expect(
          codec.decode(codec.encode(original)),
          original,
          reason: 'qualifier=$qualifier, pace=$pace',
        );
      }
    }
  });

  test('preserves nullable card fields', () {
    final original = AssistantRichContent(
      sections: [
        AssistantPlaceCarousel(
          id: 'places',
          title: 'Places',
          items: [
            const AssistantPlaceCard(
              id: 'place-1',
              name: 'Kyoto',
              location: 'Japan',
              subtitle: null,
              image: null,
              latitude: null,
              longitude: null,
            ),
          ],
        ),
        AssistantHotelCarousel(
          id: 'hotels',
          title: 'Hotels',
          items: [
            const AssistantHotelCard(
              id: 'hotel-1',
              name: 'Kyoto Hotel',
              location: 'Kyoto',
              category: null,
              rating: null,
              reviewScore: null,
              price: null,
              image: null,
              expiresAt: null,
            ),
          ],
        ),
      ],
    );
    expect(codec.decode(codec.encode(original)), original);
  });

  test('writes calendar dates and traveler count in the storage contract', () {
    final json =
        jsonDecode(codec.encode(richContentFixture())!) as Map<String, dynamic>;
    final sections = json['sections'] as List<dynamic>;
    final itinerary = sections.last as Map<String, dynamic>;
    final summary = itinerary['summary'] as Map<String, dynamic>;
    final days = itinerary['days'] as List<dynamic>;
    expect(summary['start_date'], '2026-10-01');
    expect(summary['end_date'], '2026-10-03');
    expect(days.first['date'], '2026-10-01');
    expect(summary['traveler_count'], 2);
  });

  test('preserves monetary precision as a JSON string', () {
    final json =
        jsonDecode(codec.encode(richContentFixture())!) as Map<String, dynamic>;
    final sections = json['sections'] as List<dynamic>;
    final hotelSection = sections[1] as Map<String, dynamic>;
    final items = hotelSection['items'] as List<dynamic>;
    final price = items.first['price'] as Map<String, dynamic>;
    expect(price['amount'], '9007199254740993.01');
    expect(price['qualifier'], 'per_night');
  });

  test('normalizes absent and empty content to null', () {
    expect(codec.encode(null), isNull);
    expect(codec.decode(null), isNull);
    expect(codec.encode(AssistantRichContent(sections: [])), isNull);
  });

  test('ignores unsupported types and future schema versions', () {
    expect(codec.decode(jsonEncode({'type': 'future_content'})), isNull);
    expect(
      codec.decode(jsonEncode({'type': 'rich_response', 'schema_version': 2})),
      isNull,
    );
  });

  test('unknown sections produce no renderable content', () {
    expect(
      codec.decode(
        jsonEncode({
          'type': 'rich_response',
          'schema_version': 1,
          'sections': [
            {'type': 'future_section'},
          ],
        }),
      ),
      isNull,
    );
  });

  test('malformed stored content throws for caller-level fallback', () {
    final invalidValues = [
      '',
      '{broken',
      'null',
      '[]',
      '42',
      jsonEncode({
        'type': 'rich_response',
        'schema_version': 1,
        'sections': [
          {
            'type': 'place_carousel',
            'id': 'places',
            'title': 'Places',
            'items': [],
          },
        ],
      }),
    ];
    for (final value in invalidValues) {
      expect(() => codec.decode(value), throwsFormatException);
    }
  });

  test('restored collections remain immutable', () {
    final restored = codec.decode(codec.encode(richContentFixture()))!;
    final places = restored.sections.first as AssistantPlaceCarousel;
    final itinerary = restored.sections.last as AssistantItineraryPreview;
    expect(() => restored.sections.clear(), throwsUnsupportedError);
    expect(() => places.items.clear(), throwsUnsupportedError);
    expect(() => itinerary.days.clear(), throwsUnsupportedError);
    expect(() => itinerary.summary.cities.clear(), throwsUnsupportedError);
  });
}
