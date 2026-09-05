import 'package:roamly_core/roamly_core.dart';

import '../entities/canonical_location.dart';
import '../entities/preference_types.dart';
import '../entities/user_preferences.dart';

/// Preference operations for the currently authenticated account.
abstract interface class PreferenceRepository {
  /// Returns saved preferences or the backend's new-account defaults.
  ///
  /// Authentication and network failures remain failures; they must not
  /// be interpreted as empty or completed onboarding.
  Future<Result<UserPreferences>> getPreferences();

  /// Replaces the complete selection and completes onboarding.
  ///
  /// Requires one through five interests. Local and international scopes
  /// require a selected home location.
  ///
  /// Returns the backend-confirmed state after a successful save.
  Future<Result<UserPreferences>> savePreferences({
    required TravelStyle travelStyle,
    required Set<TravelInterest> interests,
    required BudgetTier budgetTier,
    required TripPace tripPace,
    required RecommendationScope recommendationScope,
    required CanonicalLocation? homeLocation,
  });

  /// Completes onboarding without fabricating preference selections.
  ///
  /// Existing saved selections are preserved by the backend.
  Future<Result<UserPreferences>> skipOnboarding();
}
