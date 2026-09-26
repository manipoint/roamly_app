import 'dart:convert';

import 'package:roamly_networking/roamly_networking.dart';

import '../../domain/entities/assistant_content_types.dart';
import '../../domain/entities/assistant_rich_content.dart';
import '../mappers/assistant_rich_content_mapper.dart';
import '../models/assistant_rich_content_model.dart';

/// Stores rich content using the version-1 rich-response JSON contract.
///
/// Keep existing stored versions readable when introducing future schemas.
final class AssistantRichContentCodec {
  const AssistantRichContentCodec();

  static const _mapper = AssistantRichContentMapper();

  /// Empty content is stored as null because it has no renderable sections.
  String? encode(AssistantRichContent? content) {
    if (content == null || content.isEmpty) return null;

    return jsonEncode({
      'type': 'rich_response',
      'schema_version': 1,
      'sections': content.sections.map(_sectionToJson).toList(growable: false),
    });
  }

  /// Returns null for absent or unsupported content.
  ///
  /// Malformed stored content throws FormatException. The local data source
  /// handles that failure while preserving the message's plain text.
  AssistantRichContent? decode(String? value) {
    if (value == null) return null;

    final decoded = jsonDecode(value);
    final json = JsonReader({'content': decoded}).object('content');

    final model = AssistantRichContentModel.tryFromJson(json);
    if (model == null) return null;

    final content = _mapper.map(model);
    return content.isEmpty ? null : content;
  }

  Map<String, Object?> _sectionToJson(AssistantContentSection section) {
    return switch (section) {
      AssistantPlaceCarousel value => {
        'type': 'place_carousel',
        'id': value.id,
        'title': value.title,
        'items': value.items.map(_placeToJson).toList(growable: false),
      },
      AssistantHotelCarousel value => {
        'type': 'hotel_carousel',
        'id': value.id,
        'title': value.title,
        'items': value.items.map(_hotelToJson).toList(growable: false),
      },
      AssistantItineraryPreview value => {
        'type': 'itinerary_preview',
        'id': value.id,
        'title': value.title,
        'itinerary_id': value.itineraryId,
        'summary': _summaryToJson(value.summary),
        'days': value.days.map(_dayToJson).toList(growable: false),
      },
    };
  }

  Map<String, Object?>? _mediaToJson(AssistantMedia? media) {
    if (media == null) return null;

    return {
      'url': media.uri.toString(),
      'alt_text': media.altText,
      'width': media.width,
      'height': media.height,
    };
  }

  Map<String, Object?>? _moneyToJson(AssistantMoney? money) {
    if (money == null) return null;

    return {
      'amount': money.amount,
      'currency': money.currency,
      'qualifier': switch (money.qualifier) {
        AssistantMoneyQualifier.total => 'total',
        AssistantMoneyQualifier.perNight => 'per_night',
        AssistantMoneyQualifier.from => 'from',
      },
    };
  }

  Map<String, Object?> _placeToJson(AssistantPlaceCard place) {
    return {
      'id': place.id,
      'name': place.name,
      'location': place.location,
      'subtitle': place.subtitle,
      'image': _mediaToJson(place.image),
      'latitude': place.latitude,
      'longitude': place.longitude,
    };
  }

  Map<String, Object?> _hotelToJson(AssistantHotelCard hotel) {
    return {
      'id': hotel.id,
      'name': hotel.name,
      'location': hotel.location,
      'category': hotel.category,
      'rating': hotel.rating,
      'review_score': hotel.reviewScore?.toString(),
      'price': _moneyToJson(hotel.price),
      'image': _mediaToJson(hotel.image),
      'expires_at': hotel.expiresAt?.toUtc().toIso8601String(),
    };
  }

  Map<String, Object?> _summaryToJson(AssistantItinerarySummary summary) {
    return {
      'title': summary.title,
      'start_date': _calendarDate(summary.startDate),
      'end_date': _calendarDate(summary.endDate),
      'duration_days': summary.durationDays,
      'traveler_count': summary.travelerCount,
      'cities': summary.cities,
      'pace': switch (summary.pace) {
        null => null,
        AssistantItineraryPace.relaxed => 'relaxed',
        AssistantItineraryPace.balanced => 'balanced',
        AssistantItineraryPace.packed => 'packed',
      },
      'cover_image': _mediaToJson(summary.coverImage),
    };
  }

  Map<String, Object?> _dayToJson(AssistantItineraryDayPreview day) {
    return {
      'day_number': day.dayNumber,
      'date': _calendarDate(day.date),
      'title': day.title,
      'subtitle': day.subtitle,
    };
  }

  /// Serializes calendar components without timezone conversion.
  static String _calendarDate(DateTime value) {
    if (value.year < 1 || value.year > 9999) {
      throw ArgumentError('Calendar date year must be between 1 and 9999.');
    }

    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
