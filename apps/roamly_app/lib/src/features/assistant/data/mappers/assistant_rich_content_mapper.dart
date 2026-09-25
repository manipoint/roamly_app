import 'package:roamly_app/src/features/assistant/data/models/assistant_rich_content_model.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_rich_content.dart';

final class AssistantRichContentMapper {
  const AssistantRichContentMapper();
  AssistantRichContent map(AssistantRichContentModel model) {
    return AssistantRichContent(sections: model.sections.map(_mapSection));
  }

  AssistantContentSection _mapSection(AssistantContentSectionModel section) {
    return switch (section) {
      AssistantPlaceCarouselModel model => AssistantPlaceCarousel(
        id: model.id,
        title: model.title,
        items: model.items.map(_mapPlace),
      ),
      AssistantHotelCarouselModel model => AssistantHotelCarousel(
        id: model.id,
        title: model.title,
        items: model.items.map(_mapHotel),
      ),
      AssistantItineraryPreviewModel model => AssistantItineraryPreview(
        id: model.id,
        title: model.title,
        itineraryId: model.itineraryId,
        summary: _mapSummary(model.summary),
        days: model.days.map(_mapDay),
      ),
    };
  }

  AssistantPlaceCard _mapPlace(AssistantPlaceCardModel model) {
    return AssistantPlaceCard(
      id: model.id,
      name: model.name,
      location: model.location,
      subtitle: model.subtitle,
      image: _mapMedia(model.image),
      latitude: model.latitude,
      longitude: model.longitude,
    );
  }

  AssistantMedia? _mapMedia(AssistantMediaModel? image) {
    if (image == null) return null;
    return AssistantMedia(
      uri: image.uri,
      altText: image.altText,
      height: image.height,
      width: image.width,
    );
  }

  AssistantHotelCard _mapHotel(AssistantHotelCardModel model) {
    return AssistantHotelCard(
      id: model.id,
      name: model.name,
      location: model.location,
      category: model.category,
      image: _mapMedia(model.image),
      rating: model.rating,
      reviewScore: model.reviewScore,
      price: _mapMoney(model.price),
      expiresAt: model.expiresAt,
    );
  }

  AssistantMoney? _mapMoney(AssistantMoneyModel? price) {
    if (price == null) return null;
    return AssistantMoney(
      amount: price.amount,
      currency: price.currency,
      qualifier: price.qualifier,
    );
  }

  AssistantItinerarySummary _mapSummary(
    AssistantItinerarySummaryModel summary,
  ) {
    return AssistantItinerarySummary(
      title: summary.title,
      startDate: summary.startDate,
      endDate: summary.endDate,
      durationDays: summary.durationDays,
      cities: summary.cities,
      pace: summary.pace,
      coverImage: _mapMedia(summary.coverImage),
      travelerCount: summary.travelerCount,
    );
  }

  AssistantItineraryDayPreview _mapDay(AssistantItineraryDayPreviewModel day) {
    return AssistantItineraryDayPreview(
      dayNumber: day.dayNumber,
      date: day.date,
      title: day.title,
      subtitle: day.subtitle,
    );
  }
}
