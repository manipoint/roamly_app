import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/canonical_location.dart';
import '../../domain/entities/preference_types.dart';
import '../../domain/entities/user_preferences.dart';
import '../state/preference_draft.dart';

/// Provides unsaved selections for the active preference flow.
final preferenceDraftControllerProvider =
    NotifierProvider.autoDispose<PreferenceDraftController, PreferenceDraft>(
      PreferenceDraftController.new,
    );

/// Coordinates synchronous edits without performing network requests.
final class PreferenceDraftController extends Notifier<PreferenceDraft> {
  @override
  PreferenceDraft build() => PreferenceDraft();

  /// Initializes an editing flow from saved preferences.
  ///
  /// Call once when entering the flow, never from every widget rebuild.
  void initializeFrom(UserPreferences preferences) {
    state = PreferenceDraft.fromPreferences(preferences);
  }

  void selectTravelStyle(TravelStyle style) {
    state = state.copyWith(travelStyle: style);
  }

  /// Adds or removes an interest.
  ///
  /// Returns false when adding another interest would exceed the limit.
  /// Removing an existing interest is always allowed.
  bool toggleInterest(TravelInterest interest) {
    final updatedInterests = Set<TravelInterest>.of(state.interests);

    if (updatedInterests.remove(interest)) {
      state = state.copyWith(interests: updatedInterests);
      return true;
    }

    if (updatedInterests.length >= PreferenceDraft.maximumInterests) {
      return false;
    }

    updatedInterests.add(interest);
    state = state.copyWith(interests: updatedInterests);
    return true;
  }

  void selectBudgetTier(BudgetTier budgetTier) {
    state = state.copyWith(budgetTier: budgetTier);
  }

  void selectTripPace(TripPace tripPace) {
    state = state.copyWith(tripPace: tripPace);
  }

  /// Retains the selected home city when switching geographic scope.
  void selectRecommendationScope(RecommendationScope scope) {
    state = state.copyWith(recommendationScope: scope);
  }

  void selectHomeLocation(CanonicalLocation location) {
    state = state.copyWith(homeLocation: location);
  }

  /// Clears resolved metadata when the city is removed or its text changes.
  void clearHomeLocation() {
    state = state.copyWith(clearHomeLocation: true);
  }

  void reset() {
    state = PreferenceDraft();
  }
}
