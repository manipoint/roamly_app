import 'canonical_location.dart';
import 'preference_types.dart';

/// Saved travel preferences and onboarding state returned by the backend.
final class UserPreferences {
  UserPreferences({
    required this.travelStyle,
    required Iterable<TravelInterest> interests,
    required this.budgetTier,
    required this.tripPace,
    required this.recommendationScope,
    required this.homeLocation,
    required this.onboardingCompleted,
    required this.personalizationReady,
    required this.onboardingCompletedAt,
    required this.createdAt,
    required this.updatedAt,
  }) : interests = Set<TravelInterest>.unmodifiable(interests);

  /// May be absent when onboarding has not been completed or was skipped.
  final TravelStyle? travelStyle;

  /// Unique interests; their selection order has no business meaning.
  final Set<TravelInterest> interests;

  final BudgetTier? budgetTier;
  final TripPace? tripPace;
  final RecommendationScope recommendationScope;
  final CanonicalLocation? homeLocation;

  /// Backend-owned flag used by the application's onboarding route gate.
  final bool onboardingCompleted;

  /// Backend-owned flag indicating whether personalization inputs are ready.
  final bool personalizationReady;

  final DateTime? onboardingCompletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UserPreferences &&
            travelStyle == other.travelStyle &&
            interests.length == other.interests.length &&
            interests.containsAll(other.interests) &&
            budgetTier == other.budgetTier &&
            tripPace == other.tripPace &&
            recommendationScope == other.recommendationScope &&
            homeLocation == other.homeLocation &&
            onboardingCompleted == other.onboardingCompleted &&
            personalizationReady == other.personalizationReady &&
            onboardingCompletedAt == other.onboardingCompletedAt &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    travelStyle,
    Object.hashAllUnordered(interests),
    budgetTier,
    tripPace,
    recommendationScope,
    homeLocation,
    onboardingCompleted,
    personalizationReady,
    onboardingCompletedAt,
    createdAt,
    updatedAt,
  );
}
