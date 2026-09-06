import '../../domain/entities/canonical_location.dart';
import '../../domain/entities/preference_types.dart';
import '../models/user_preferences_model.dart';

/// Remote preference operations for the authenticated account.
///
/// Returns parsed API models. Transport and parsing failures propagate
/// to the repository, which converts them into application failures.
abstract interface class PreferenceRemoteDataSource {
  /// Fetches saved preferences or the backend's new-account defaults.
  Future<UserPreferencesModel> getPreferences();

  /// Replaces the complete preference selection.
  ///
  /// A null home location is sent explicitly so a previous location
  /// can be cleared when the selected scope permits it.
  Future<UserPreferencesModel> savePreferences({
    required TravelStyle travelStyle,
    required Set<TravelInterest> interests,
    required BudgetTier budgetTier,
    required TripPace tripPace,
    required RecommendationScope recommendationScope,
    required CanonicalLocation? homeLocation,
  });

  /// Completes onboarding without replacing existing selections.
  Future<UserPreferencesModel> skipOnboarding();
}
