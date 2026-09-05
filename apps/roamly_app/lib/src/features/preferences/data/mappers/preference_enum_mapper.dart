import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';

/// Maps preference enums to and from the backend's wire values.
abstract final class PreferenceEnumMapper {
  static TravelStyle travelStyleFromJson(Object? value) {
    return switch (value) {
      'beaches' => TravelStyle.beaches,
      'adventure' => TravelStyle.adventure,
      'culture' => TravelStyle.culture,
      'food' => TravelStyle.food,
      'luxury' => TravelStyle.luxury,
      'nature' => TravelStyle.nature,
      _ => throw const FormatException('Invalid travel_style.'),
    };
  }

  static String travelStyleToJson(TravelStyle value) {
    return switch (value) {
      TravelStyle.beaches => 'beaches',
      TravelStyle.adventure => 'adventure',
      TravelStyle.culture => 'culture',
      TravelStyle.food => 'food',
      TravelStyle.luxury => 'luxury',
      TravelStyle.nature => 'nature',
    };
  }

  static TravelInterest interestFromJson(Object? value) {
    return switch (value) {
      'events' => TravelInterest.events,
      'hiking' => TravelInterest.hiking,
      'history' => TravelInterest.history,
      'local_culture' => TravelInterest.localCulture,
      'nightlife' => TravelInterest.nightlife,
      'photography' => TravelInterest.photography,
      'shopping' => TravelInterest.shopping,
      'wellness' => TravelInterest.wellness,
      'wildlife' => TravelInterest.wildlife,
      _ => throw const FormatException('Invalid travel interest.'),
    };
  }

  static String interestToJson(TravelInterest value) {
    return switch (value) {
      TravelInterest.hiking => 'hiking',
      TravelInterest.photography => 'photography',
      TravelInterest.nightlife => 'nightlife',
      TravelInterest.wellness => 'wellness',
      TravelInterest.history => 'history',
      TravelInterest.wildlife => 'wildlife',
      TravelInterest.shopping => 'shopping',
      TravelInterest.localCulture => 'local_culture',
      TravelInterest.events => 'events',
    };
  }

  static BudgetTier budgetTierFromJson(Object? value) {
    return switch (value) {
      'budget' => BudgetTier.budget,
      'mid_range' => BudgetTier.midRange,
      'premium' => BudgetTier.premium,
      'luxury' => BudgetTier.luxury,
      _ => throw const FormatException('Invalid budget_tier.'),
    };
  }

  static String budgetTierToJson(BudgetTier value) {
    return switch (value) {
      BudgetTier.budget => 'budget',
      BudgetTier.midRange => 'mid_range',
      BudgetTier.premium => 'premium',
      BudgetTier.luxury => 'luxury',
    };
  }

  static TripPace tripPaceFromJson(Object? value) {
    return switch (value) {
      'relaxed' => TripPace.relaxed,
      'balanced' => TripPace.balanced,
      'packed' => TripPace.packed,
      _ => throw const FormatException('Invalid trip_pace.'),
    };
  }

  static String tripPaceToJson(TripPace value) {
    return switch (value) {
      TripPace.relaxed => 'relaxed',
      TripPace.balanced => 'balanced',
      TripPace.packed => 'packed',
    };
  }

  static RecommendationScope recommendationScopeFromJson(Object? value) {
    return switch (value) {
      'local' => RecommendationScope.local,
      'international' => RecommendationScope.international,
      'both' => RecommendationScope.both,
      _ => throw const FormatException('Invalid recommendation_scope.'),
    };
  }

  static String recommendationScopeToJson(RecommendationScope value) {
    return switch (value) {
      RecommendationScope.local => 'local',
      RecommendationScope.international => 'international',
      RecommendationScope.both => 'both',
    };
  }
}
