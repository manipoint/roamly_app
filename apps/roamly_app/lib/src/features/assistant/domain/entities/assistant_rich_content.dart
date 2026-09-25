import 'package:roamly_app/src/features/assistant/domain/entities/assistant_content_types.dart';
import 'package:roamly_core/roamly_core.dart';

final class AssistantMedia {
  const AssistantMedia({
    required this.uri,
    required this.altText,
    this.width,
    this.height,
  });

  final Uri uri;
  final String altText;
  final int? width;
  final int? height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistantMedia &&
          uri == other.uri &&
          altText == other.altText &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(uri, altText, width, height);
}

final class AssistantMoney {
  const AssistantMoney({
    required this.amount,
    required this.currency,
    required this.qualifier,
  });
  final String amount;
  final String currency;
  final AssistantMoneyQualifier qualifier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistantMoney &&
          amount == other.amount &&
          currency == other.currency &&
          qualifier == other.qualifier;

  @override
  int get hashCode => Object.hash(amount, currency, qualifier);
}

final class AssistantPlaceCard {
  const AssistantPlaceCard({
    required this.id,
    required this.name,
    required this.location,
    required this.subtitle,
    required this.image,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String location;
  final String? subtitle;
  final AssistantMedia? image;
  final double? latitude;
  final double? longitude;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistantPlaceCard &&
          id == other.id &&
          name == other.name &&
          location == other.location &&
          subtitle == other.subtitle &&
          image == other.image &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode =>
      Object.hash(id, name, location, subtitle, image, latitude, longitude);
}

final class AssistantHotelCard {
  const AssistantHotelCard({
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
  final AssistantMoney? price;
  final AssistantMedia? image;
  final DateTime? expiresAt;

  bool isExpiredAt(DateTime now) {
    final expiry = expiresAt;
    return expiry != null && !now.isBefore(expiry);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistantHotelCard &&
          id == other.id &&
          name == other.name &&
          location == other.location &&
          category == other.category &&
          rating == other.rating &&
          reviewScore == other.reviewScore &&
          price == other.price &&
          image == other.image &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    location,
    category,
    rating,
    reviewScore,
    price,
    image,
    expiresAt,
  );
}

sealed class AssistantContentSection {
  const AssistantContentSection({required this.id, required this.title});

  final String id;
  final String title;
}

final class AssistantPlaceCarousel extends AssistantContentSection {
  AssistantPlaceCarousel({
    required super.id,
    required super.title,
    required Iterable<AssistantPlaceCard> items,
  }) : items = List<AssistantPlaceCard>.unmodifiable(items);

  final List<AssistantPlaceCard> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistantPlaceCarousel &&
          id == other.id &&
          title == other.title &&
          CollectionEquality.ordered(items, other.items);

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, title, Object.hashAll(items));
}

final class AssistantHotelCarousel extends AssistantContentSection {
  AssistantHotelCarousel({
    required super.id,
    required super.title,
    required Iterable<AssistantHotelCard> items,
  }) : items = List<AssistantHotelCard>.unmodifiable(items);

  final List<AssistantHotelCard> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistantHotelCarousel &&
          id == other.id &&
          title == other.title &&
          CollectionEquality.ordered(items, other.items);

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, title, Object.hashAll(items));
}

final class AssistantItineraryPreview extends AssistantContentSection {
  AssistantItineraryPreview({
    required super.id,
    required super.title,
    required this.itineraryId,
    required this.summary,
    required Iterable<AssistantItineraryDayPreview> days,
  }) : days = List<AssistantItineraryDayPreview>.unmodifiable(days);

  final String itineraryId;
  final AssistantItinerarySummary summary;
  final List<AssistantItineraryDayPreview> days;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistantItineraryPreview &&
          id == other.id &&
          title == other.title &&
          itineraryId == other.itineraryId &&
          summary == other.summary &&
          CollectionEquality.ordered(days, other.days);

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    itineraryId,
    summary,
    Object.hashAll(days),
  );
}

final class AssistantItinerarySummary {
  AssistantItinerarySummary({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required Iterable<String> cities,
    this.travelerCount,
    this.pace,
    this.coverImage,
  }) : cities = List<String>.unmodifiable(cities);

  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final int? travelerCount;
  final List<String> cities;
  final AssistantItineraryPace? pace;
  final AssistantMedia? coverImage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistantItinerarySummary &&
          title == other.title &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          durationDays == other.durationDays &&
          travelerCount == other.travelerCount &&
          CollectionEquality.ordered(cities, other.cities) &&
          pace == other.pace &&
          coverImage == other.coverImage;

  @override
  int get hashCode => Object.hash(
    title,
    startDate,
    endDate,
    durationDays,
    travelerCount,
    Object.hashAll(cities),
    pace,
    coverImage,
  );
}

final class AssistantItineraryDayPreview {
  const AssistantItineraryDayPreview({
    required this.dayNumber,
    required this.date,
    required this.title,
    this.subtitle,
  });

  final int dayNumber;
  final DateTime date;
  final String title;
  final String? subtitle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistantItineraryDayPreview &&
          dayNumber == other.dayNumber &&
          date == other.date &&
          title == other.title &&
          subtitle == other.subtitle;

  @override
  int get hashCode => Object.hash(dayNumber, date, title, subtitle);
}

final class AssistantRichContent {
  AssistantRichContent({required Iterable<AssistantContentSection> sections})
    : sections = List<AssistantContentSection>.unmodifiable(sections);

  final List<AssistantContentSection> sections;

  bool get isEmpty => sections.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistantRichContent &&
          CollectionEquality.ordered(sections, other.sections);

  @override
  int get hashCode => Object.hashAll(sections);
}


