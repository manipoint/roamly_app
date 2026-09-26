import 'package:roamly_app/src/features/assistant/domain/entities/assistant_content_types.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_rich_content.dart';

AssistantRichContent richContentFixture({
  AssistantMoneyQualifier qualifier = AssistantMoneyQualifier.perNight,
  AssistantItineraryPace? pace = AssistantItineraryPace.balanced,
}) {
  final media = AssistantMedia(
    uri: Uri.parse('https://images.example.com/kyoto.jpg'),
    altText: 'Kyoto temple',
    width: 1200,
    height: 800,
  );
  return AssistantRichContent(
    sections: [
      AssistantPlaceCarousel(
        id: 'places',
        title: 'Suggested places',
        items: [
          AssistantPlaceCard(
            id: 'gion',
            name: 'Gion',
            location: 'Kyoto, Japan',
            subtitle: 'Historic district',
            image: media,
            latitude: 35.003,
            longitude: 135.778,
          ),
        ],
      ),
      AssistantHotelCarousel(
        id: 'hotels',
        title: 'Suggested hotels',
        items: [
          AssistantHotelCard(
            id: 'hotel-1',
            name: 'Kyoto Hotel',
            location: 'Kyoto, Japan',
            category: 'Luxury',
            rating: 5,
            reviewScore: 9.4,
            price: AssistantMoney(
              amount: '9007199254740993.01',
              currency: 'JPY',
              qualifier: qualifier,
            ),
            image: media,
            expiresAt: DateTime.utc(2026, 10, 1, 12, 30),
          ),
        ],
      ),
      AssistantItineraryPreview(
        id: 'generated-itinerary',
        title: 'Your itinerary',
        itineraryId: '00000000-0000-4000-8000-000000000004',
        summary: AssistantItinerarySummary(
          title: 'Japan Adventure',
          startDate: DateTime.utc(2026, 10, 1),
          endDate: DateTime.utc(2026, 10, 3),
          durationDays: 3,
          travelerCount: 2,
          cities: ['Kyoto', 'Tokyo'],
          pace: pace,
          coverImage: media,
        ),
        days: [
          AssistantItineraryDayPreview(
            dayNumber: 1,
            date: DateTime.utc(2026, 10, 1),
            title: 'Explore Kyoto',
            subtitle: 'Visit Gion',
          ),
        ],
      ),
    ],
  );
}
