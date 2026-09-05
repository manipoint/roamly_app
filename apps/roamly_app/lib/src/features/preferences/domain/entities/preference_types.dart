/// Primary travel experience selected by the user.
enum TravelStyle { beaches, adventure, food, luxury, nature, culture }

/// Interests used to personalize destination suggestions.
enum TravelInterest {
  hiking,
  photography,
  nightlife,
  wellness,
  history,
  wildlife,
  shopping,
  localCulture,
  events,
}

/// Relative spending preference, not an exact trip price.
enum BudgetTier { budget, midRange, premium, luxury }

/// Preferred density of activities in an itinerary.
enum TripPace { relaxed, balanced, packed }

/// Geographic scope relative to the user's selected home country.
enum RecommendationScope {
  local,
  international,
  both;

  /// Whether this scope requires a selected home location.
  bool get requiresHomeLocation => this != RecommendationScope.both;
}
