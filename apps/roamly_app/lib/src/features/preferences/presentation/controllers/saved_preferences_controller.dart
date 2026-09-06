import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_core/roamly_core.dart';

import '../../domain/entities/user_preferences.dart';
import '../providers/preference_dependency_providers.dart';
import '../state/preference_draft.dart';

/// Lazily owns the authenticated user's server-confirmed preferences.
///
/// The first API request runs only when a screen or route gate watches this
/// provider. Automatic retries are disabled to avoid duplicate API cost.
final savedPreferencesControllerProvider =
    AsyncNotifierProvider.autoDispose<
      SavedPreferencesController,
      UserPreferences
    >(SavedPreferencesController.new, retry: (_, _) => null);

final class SavedPreferencesController extends AsyncNotifier<UserPreferences> {
  @override
  Future<UserPreferences> build() async {
    final result = await ref
        .watch(preferenceRepositoryProvider)
        .getPreferences();

    return _unwrap(result);
  }

  /// Retries loading after an error or refreshes the saved server state.
  Future<bool> reload() {
    return _execute(
      () => ref.read(preferenceRepositoryProvider).getPreferences(),
    );
  }

  /// Saves a complete draft and replaces state with the server response.
  ///
  /// Returns false without a request when the draft is incomplete or another
  /// preference operation is already running.
  Future<bool> saveDraft(PreferenceDraft draft) {
    if (state.isLoading || !draft.canSubmit) {
      return Future<bool>.value(false);
    }

    return _execute(
      () => ref
          .read(preferenceRepositoryProvider)
          .savePreferences(
            travelStyle: draft.travelStyle!,
            interests: draft.interests,
            budgetTier: draft.budgetTier!,
            tripPace: draft.tripPace!,
            recommendationScope: draft.recommendationScope,
            homeLocation: draft.homeLocation,
          ),
    );
  }

  /// Completes onboarding while retaining any existing saved selections.
  Future<bool> skipOnboarding() {
    if (state.isLoading) {
      return Future<bool>.value(false);
    }

    return _execute(
      () => ref.read(preferenceRepositoryProvider).skipOnboarding(),
    );
  }

  Future<bool> _execute(
    Future<Result<UserPreferences>> Function() operation,
  ) async {
    state = const AsyncLoading<UserPreferences>();

    state = await AsyncValue.guard<UserPreferences>(() async {
      final result = await operation();
      return _unwrap(result);
    });

    return !state.hasError;
  }

  static UserPreferences _unwrap(Result<UserPreferences> result) {
    return result.fold(
      onSuccess: (preferences) => preferences,
      onFailure: (failure) => throw failure,
    );
  }
}
