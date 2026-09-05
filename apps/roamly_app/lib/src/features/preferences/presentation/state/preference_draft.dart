import '../../domain/entities/canonical_location.dart';
import '../../domain/entities/preference_types.dart';
import '../../domain/entities/user_preferences.dart';

/// Immutable, unsaved selections shared across onboarding screens.
final class PreferenceDraft {
  PreferenceDraft({
    this.travelStyle,
    Iterable<TravelInterest> interests = const <TravelInterest>[],
    this.budgetTier,
    this.tripPace,
    this.recommendationScope = RecommendationScope.both,
    this.homeLocation,
  }) : interests = Set<TravelInterest>.unmodifiable(interests);

  /// Creates an editable starting point from saved preferences.
  factory PreferenceDraft.fromPreferences(UserPreferences preferences) {
    return PreferenceDraft(
      travelStyle: preferences.travelStyle,
      interests: preferences.interests,
      budgetTier: preferences.budgetTier,
      tripPace: preferences.tripPace,
      recommendationScope: preferences.recommendationScope,
      homeLocation: preferences.homeLocation,
    );
  }

  static const int minimumInterests = 1;
  static const int maximumInterests = 5;

  final TravelStyle? travelStyle;
  final Set<TravelInterest> interests;
  final BudgetTier? budgetTier;
  final TripPace? tripPace;
  final RecommendationScope recommendationScope;
  final CanonicalLocation? homeLocation;

  bool get isTravelStyleComplete => travelStyle != null;

  bool get hasValidInterestCount =>
      interests.length >= minimumInterests &&
      interests.length <= maximumInterests;

  bool get isInterestsAndBudgetComplete =>
      hasValidInterestCount && budgetTier != null && tripPace != null;

  bool get isDiscoveryScopeComplete =>
      !recommendationScope.requiresHomeLocation || homeLocation != null;

  /// Controls submission availability, not server onboarding status.
  bool get canSubmit =>
      isTravelStyleComplete &&
      isInterestsAndBudgetComplete &&
      isDiscoveryScopeComplete;

  /// Returns a new draft while retaining unspecified selections.
  ///
  /// Use [clearHomeLocation] when the user removes or edits a selected city.
  /// Create a new [PreferenceDraft] to reset all selections.
  PreferenceDraft copyWith({
    TravelStyle? travelStyle,
    Iterable<TravelInterest>? interests,
    BudgetTier? budgetTier,
    TripPace? tripPace,
    RecommendationScope? recommendationScope,
    CanonicalLocation? homeLocation,
    bool clearHomeLocation = false,
  }) {
    if (clearHomeLocation && homeLocation != null) {
      throw ArgumentError('Cannot provide homeLocation while clearing it.');
    }

    return PreferenceDraft(
      travelStyle: travelStyle ?? this.travelStyle,
      interests: interests ?? this.interests,
      budgetTier: budgetTier ?? this.budgetTier,
      tripPace: tripPace ?? this.tripPace,
      recommendationScope: recommendationScope ?? this.recommendationScope,
      homeLocation: clearHomeLocation
          ? null
          : homeLocation ?? this.homeLocation,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PreferenceDraft &&
            travelStyle == other.travelStyle &&
            interests.length == other.interests.length &&
            interests.containsAll(other.interests) &&
            budgetTier == other.budgetTier &&
            tripPace == other.tripPace &&
            recommendationScope == other.recommendationScope &&
            homeLocation == other.homeLocation;
  }

  @override
  int get hashCode => Object.hash(
    travelStyle,
    Object.hashAllUnordered(interests),
    budgetTier,
    tripPace,
    recommendationScope,
    homeLocation,
  );
}
