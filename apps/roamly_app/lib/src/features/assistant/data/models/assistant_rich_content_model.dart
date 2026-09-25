import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_networking/roamly_networking.dart';

enum AssistantMoneyQualifier { total, perNight, from }

enum AssistantItineraryPace { relaxed, balanced, packed }

final class AssistantMediaModel {
  final Uri uri;
  final String altText;
  final int? width;
  final int? height;

  AssistantMediaModel._({
    required this.uri,
    required this.altText,
    required this.width,
    required this.height,
  });

  factory AssistantMediaModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);
    final width = reader.nullable(
      'width',
      () => reader.integer('width', min: 1),
      allowMissing: true,
    );
    final height = reader.nullable(
      'height',
      () => reader.integer('height', min: 1),
      allowMissing: true,
    );
    if ((width == null) != (height == null)) {
      throw const FormatException(
        'Assistant media width and height must be provided together.',
      );
    }
    return AssistantMediaModel._(
      uri: reader.uri('url', allowedSchemes: const {'https'}, maxLength: 2048),
      altText: reader.string(
        'alt_text',
        trim: true,
        minLength: 1,
        maxLength: 300,
      ),
      width: width,
      height: height,
    );
  }
}

final class AssistantMoneyModel {
  const AssistantMoneyModel._({
    required this.amount,
    required this.currency,
    required this.qualifier,
  });
  final String amount;
  final String currency;
  final AssistantMoneyQualifier qualifier;
  factory AssistantMoneyModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);
    final amount = reader.string(
      'amount',
      trim: true,
      minLength: 1,
      maxLength: 100,
    );
    if (!RoamlyValueValidators.isValidAmountPattern(amount)) {
      throw const FormatException('Invalid assistant monetary amount.');
    }
    final currency = reader.string(
      'currency',
      trim: true,
      minLength: 3,
      maxLength: 3,
    );
    if (!RoamlyValueValidators.isValidCurrencyCode(currency)) {
      throw const FormatException('Invalid assistant currency code.');
    }
    final rawQualifier = reader.string('qualifier', trim: true, minLength: 1);
    final qualifier = switch (rawQualifier) {
      'total' => AssistantMoneyQualifier.total,
      'per_night' => AssistantMoneyQualifier.perNight,
      'from' => AssistantMoneyQualifier.from,
      _ => throw const FormatException('Invalid assistant money qualifier.'),
    };
    return AssistantMoneyModel._(
      amount: amount,
      currency: currency,
      qualifier: qualifier,
    );
  }
}

final class AssistantPlaceCardModel {
  const AssistantPlaceCardModel._({
    required this.id,
    required this.name,
    required this.location,
    this.subtitle,
    this.image,
    this.latitude,
    this.longitude,
  });
  final String id;
  final String name;
  final String location;
  final String? subtitle;
  final AssistantMediaModel? image;
  final double? latitude;
  final double? longitude;
  factory AssistantPlaceCardModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);
    final latitude = reader.nullable<double>(
      'latitude',
      () => reader.number('latitude', min: -90, max: 90),
      allowMissing: true,
    );

    final longitude = reader.nullable<double>(
      'longitude',
      () => reader.number('longitude', min: -180, max: 180),
      allowMissing: true,
    );
    if ((latitude == null) != (longitude == null)) {
      throw const FormatException(
        'Assistant place coordinates must be provided together.',
      );
    }
    return AssistantPlaceCardModel._(
      id: reader.string('id', trim: true, minLength: 1, maxLength: 300),
      name: reader.string('name', trim: true, minLength: 1, maxLength: 200),
      location: reader.string(
        'location',
        trim: true,
        minLength: 1,
        maxLength: 200,
      ),
      subtitle: reader.nullable<String>(
        'subtitle',
        () =>
            reader.string('subtitle', trim: true, minLength: 1, maxLength: 200),
        allowMissing: true,
      ),
      image: reader.nullable<AssistantMediaModel>(
        'image',
        () => AssistantMediaModel.fromJson(reader.object('image')),
        allowMissing: true,
      ),
      latitude: latitude,
      longitude: longitude,
    );
  }
}

final class AssistantHotelCardModel {
  const AssistantHotelCardModel._({
    required this.id,
    required this.name,
    required this.location,
    required this.category,
    required this.rating,
    required this.reviewScore,
    required this.price,
    required this.image,
    required this.expiresAt,
  });
  final String id;
  final String name;
  final String location;
  final String? category;
  final int? rating;
  final double? reviewScore;
  final AssistantMoneyModel? price;
  final AssistantMediaModel? image;
  final DateTime? expiresAt;
  factory AssistantHotelCardModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);
    return AssistantHotelCardModel._(
      id: reader.string('id', trim: true, minLength: 1, maxLength: 300),
      name: reader.string('name', trim: true, minLength: 1, maxLength: 200),
      location: reader.string(
        'location',
        trim: true,
        minLength: 1,
        maxLength: 200,
      ),
      category: reader.nullable(
        'category',
        () =>
            reader.string('category', trim: true, minLength: 1, maxLength: 100),
        allowMissing: true,
      ),
      rating: reader.nullable<int>(
        'rating',
        () => reader.integer('rating', min: 1, max: 5),
        allowMissing: true,
      ),
      reviewScore: reader.nullable(
        'review_score',
        () => reader.decimalNumber('review_score', min: 1, max: 10),
        allowMissing: true,
      ),
      price: reader.nullable(
        'price',
        () => AssistantMoneyModel.fromJson(reader.object('price')),
        allowMissing: true,
      ),
      image: reader.nullable(
        'image',
        () => AssistantMediaModel.fromJson(reader.object('image')),
        allowMissing: true,
      ),
      expiresAt: reader.nullable<DateTime>(
        'expires_at',
        () => reader.dateTime('expires_at'),
        allowMissing: true,
      ),
    );
  }
}

sealed class AssistantContentSectionModel {
  const AssistantContentSectionModel();
  static AssistantContentSectionModel? tryFromJson(Map<String, Object?> json) {
    final type = JsonReader(json).string('type', trim: true, minLength: 1);
    return switch (type) {
      'place_carousel' => AssistantPlaceCarouselModel.fromJson(json),
      'hotel_carousel' => AssistantHotelCarouselModel.fromJson(json),
      'itinerary_preview' => AssistantItineraryPreviewModel.fromJson(json),
      _ => null,
    };
  }
}

final class AssistantPlaceCarouselModel extends AssistantContentSectionModel {
  const AssistantPlaceCarouselModel._({
    required this.id,
    required this.title,
    required this.items,
  });
  final String id;
  final String title;
  final List<AssistantPlaceCardModel> items;
  factory AssistantPlaceCarouselModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);

    return AssistantPlaceCarouselModel._(
      id: reader.string('id', trim: true, minLength: 1, maxLength: 100),
      title: reader.string('title', trim: true, minLength: 1, maxLength: 120),
      items: reader.objectList(
        'items',
        parseItem: AssistantPlaceCardModel.fromJson,
        minLength: 1,
        maxLength: 5,
      ),
    );
  }
}

final class AssistantHotelCarouselModel extends AssistantContentSectionModel {
  const AssistantHotelCarouselModel._({
    required this.id,
    required this.title,
    required this.items,
  });
  final String id;
  final String title;
  final List<AssistantHotelCardModel> items;
  factory AssistantHotelCarouselModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);

    return AssistantHotelCarouselModel._(
      id: reader.string('id', trim: true, minLength: 1, maxLength: 100),
      title: reader.string('title', trim: true, minLength: 1, maxLength: 120),
      items: reader.objectList(
        'items',
        parseItem: AssistantHotelCardModel.fromJson,
        minLength: 1,
        maxLength: 5,
      ),
    );
  }
}

final class AssistantItineraryPreviewModel
    extends AssistantContentSectionModel {
  const AssistantItineraryPreviewModel._({
    required this.id,
    required this.title,
    required this.itineraryId,
    required this.summary,
    required this.days,
  });
  final String id;
  final String title;
  final String itineraryId;
  final AssistantItinerarySummaryModel summary;
  final List<AssistantItineraryDayPreviewModel> days;

  factory AssistantItineraryPreviewModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);
    final itineraryId = reader.string(
      'itinerary_id',
      trim: true,
      minLength: 1,
      maxLength: 100,
    );
    if (!RoamlyValueValidators.isValidUuid(itineraryId)) {
      throw const FormatException('Invalid itinerary id.');
    }

    return AssistantItineraryPreviewModel._(
      id: reader.string('id', trim: true, minLength: 1, maxLength: 100),
      title: reader.string('title', trim: true, minLength: 1, maxLength: 120),
      itineraryId: itineraryId,
      summary: AssistantItinerarySummaryModel.fromJson(
        reader.object('summary'),
      ),
      days: reader.objectList(
        'days',
        maxLength: 7,
        parseItem: AssistantItineraryDayPreviewModel.fromJson,
      ),
    );
  }
}

final class AssistantItinerarySummaryModel {
  const AssistantItinerarySummaryModel._({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.travelerCount,
    required this.cities,
    required this.pace,
    required this.coverImage,
  });
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final int? travelerCount;
  final List<String> cities;
  final AssistantItineraryPace? pace;
  final AssistantMediaModel? coverImage;
  factory AssistantItinerarySummaryModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);

    final startDate = reader.date('start_date');
    final endDate = reader.date('end_date');
    if (endDate.isBefore(startDate)) {
      throw const FormatException(
        'Assistant itinerary end date precedes its start date.',
      );
    }
    final durationDays = reader.integer('duration_days', min: 1);
    final expectedDuration = endDate.difference(startDate).inDays + 1;

    if (durationDays != expectedDuration) {
      throw const FormatException(
        'Assistant itinerary duration does not match its dates.',
      );
    }
    final rawPace = reader.nullable<String>(
      'pace',
      () => reader.string('pace', trim: true, minLength: 1),
      allowMissing: true,
    );
    final pace = switch (rawPace) {
      null => null,
      'relaxed' => AssistantItineraryPace.relaxed,
      'balanced' => AssistantItineraryPace.balanced,
      'packed' => AssistantItineraryPace.packed,
      _ => throw const FormatException('Invalid assistant itinerary pace.'),
    };
    final cities = reader.list<String>(
      'cities',
      maxLength: 20,
      parseItem: (value) {
        if (value is! String) {
          throw const FormatException(
            'Expected a string in assistant itinerary cities.',
          );
        }
        final city = value.trim();

        if (city.runes.length > 200) {
          throw const FormatException(
            'Assistant itinerary city exceeds the maximum length.',
          );
        }
        return city;
      },
    );
    return AssistantItinerarySummaryModel._(
      title: reader.string('title', trim: true, minLength: 1, maxLength: 200),
      startDate: startDate,
      endDate: endDate,
      durationDays: durationDays,
      travelerCount: reader.nullable<int>(
        'traveler_count',
        () => reader.integer('traveler_count', min: 1, max: 100),
        allowMissing: true,
      ),
      cities: cities,
      pace: pace,
      coverImage: reader.nullable(
        'cover_image',
        () => AssistantMediaModel.fromJson(reader.object('cover_image')),
        allowMissing: true,
      ),
    );
  }
}

final class AssistantItineraryDayPreviewModel {
  const AssistantItineraryDayPreviewModel._({
    required this.dayNumber,
    required this.date,
    required this.title,
    required this.subtitle,
  });
  final int dayNumber;
  final DateTime date;
  final String title;
  final String? subtitle;
  factory AssistantItineraryDayPreviewModel.fromJson(
    Map<String, Object?> json,
  ) {
    final reader = JsonReader(json);
    return AssistantItineraryDayPreviewModel._(
      dayNumber: reader.integer('day_number', min: 1),
      date: reader.date('date'),
      title: reader.string('title', trim: true, minLength: 1, maxLength: 200),
      subtitle: reader.nullable<String>(
        'subtitle',
        () =>
            reader.string('subtitle', trim: true, minLength: 1, maxLength: 300),
        allowMissing: true,
      ),
    );
  }
}

final class AssistantRichContentModel {
  const AssistantRichContentModel._({
    required this.schemaVersion,
    required this.sections,
  });
  static const int supportedSchemaVersion = 1;

  final int schemaVersion;
  final List<AssistantContentSectionModel> sections;
  static AssistantRichContentModel? tryFromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);
    final type = reader.string('type', trim: true, minLength: 1);
    if (type != 'rich_response') {
      return null;
    }
    final schemaVersion = reader.integer('schema_version', min: 1);

    if (schemaVersion != supportedSchemaVersion) {
      return null;
    }
    final parsedSections = reader.objectList(
      'sections',
      minLength: 1,
      maxLength: 6,
      parseItem: AssistantContentSectionModel.tryFromJson,
    );
    return AssistantRichContentModel._(
      schemaVersion: schemaVersion,
      sections: List.unmodifiable(
        parsedSections.whereType<AssistantContentSectionModel>(),
      ),
    );
  }
}
