import 'package:roamly_networking/roamly_networking.dart';

import '../../domain/entities/user_preferences.dart';
import '../mappers/preference_enum_mapper.dart';
import 'canonical_location_model.dart';

/// Parses the backend's saved preference response.
final class UserPreferencesModel {
  const UserPreferencesModel._(this._preferences);

  final UserPreferences _preferences;

  factory UserPreferencesModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);

    final interests = reader.list(
      'interests',
      parseItem: PreferenceEnumMapper.interestFromJson,
      maxLength: 5,
      unique: true,
    );

    final travelStyle = reader.nullable(
      'travel_style',
      () => PreferenceEnumMapper.travelStyleFromJson(
        reader.string('travel_style'),
      ),
    );

    final budgetTier = reader.nullable(
      'budget_tier',
      () =>
          PreferenceEnumMapper.budgetTierFromJson(reader.string('budget_tier')),
    );

    final tripPace = reader.nullable(
      'trip_pace',
      () => PreferenceEnumMapper.tripPaceFromJson(reader.string('trip_pace')),
    );

    final recommendationScope =
        PreferenceEnumMapper.recommendationScopeFromJson(
          reader.string('recommendation_scope'),
        );

    final homeLocation = reader.nullable(
      'home_location',
      () => CanonicalLocationModel.fromJson(
        reader.object('home_location'),
      ).toDomain(),
    );

    final onboardingCompleted = reader.boolean('onboarding_completed');
    final personalizationReady = reader.boolean('personalization_ready');

    final onboardingCompletedAt = reader.nullable(
      'onboarding_completed_at',
      () => reader.dateTime('onboarding_completed_at'),
    );

    final createdAt = reader.nullable(
      'created_at',
      () => reader.dateTime('created_at'),
    );

    final updatedAt = reader.nullable(
      'updated_at',
      () => reader.dateTime('updated_at'),
    );

    return UserPreferencesModel._(
      UserPreferences(
        travelStyle: travelStyle,
        interests: interests,
        budgetTier: budgetTier,
        tripPace: tripPace,
        recommendationScope: recommendationScope,
        homeLocation: homeLocation,
        onboardingCompleted: onboardingCompleted,
        personalizationReady: personalizationReady,
        onboardingCompletedAt: onboardingCompletedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );
  }

  /// Returns immutable saved preferences for application state.
  UserPreferences toDomain() => _preferences;
}
