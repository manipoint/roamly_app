import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/data/models/user_preferences_model.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';

Map<String, Object?> _payload() => {
  'travel_style': null,
  'interests': <String>[],
  'budget_tier': null,
  'trip_pace': null,
  'recommendation_scope': 'both',
  'home_location': null,
  'onboarding_completed': false,
  'personalization_ready': false,
  'onboarding_completed_at': null,
  'created_at': null,
  'updated_at': null,
};

void main() {
  test('new account accepts empty interests and null optional values', () {
    final value = UserPreferencesModel.fromJson(_payload()).toDomain();
    expect(value.interests, isEmpty);
    expect(value.travelStyle, isNull);
    expect(value.homeLocation, isNull);
    expect(value.recommendationScope, RecommendationScope.both);
    expect(value.onboardingCompleted, isFalse);
    expect(value.createdAt, isNull);
  });

  test('maps saved preferences, location and timestamps', () {
    final value = UserPreferencesModel.fromJson({
      ..._payload(),
      'travel_style': 'nature',
      'interests': ['hiking', 'local_culture'],
      'budget_tier': 'mid_range',
      'trip_pace': 'balanced',
      'recommendation_scope': 'local',
      'home_location': {
        'provider': 'google',
        'provider_location_id': 'lahore-id',
        'canonical_name': 'Lahore, Pakistan',
        'country_code': 'PK',
        'latitude': 31.5,
        'longitude': 74.3,
      },
      'onboarding_completed': true,
      'personalization_ready': true,
      'onboarding_completed_at': '2026-09-05T12:00:00+05:00',
      'created_at': '2026-09-05T07:00:00Z',
      'updated_at': '2026-09-05T07:01:00Z',
    }).toDomain();
    expect(value.travelStyle, TravelStyle.nature);
    expect(value.interests, {
      TravelInterest.hiking,
      TravelInterest.localCulture,
    });
    expect(value.budgetTier, BudgetTier.midRange);
    expect(value.tripPace, TripPace.balanced);
    expect(value.recommendationScope, RecommendationScope.local);
    expect(value.homeLocation?.countryCode, 'PK');
    expect(value.onboardingCompletedAt, DateTime.utc(2026, 9, 5, 7));
    expect(value.updatedAt, DateTime.utc(2026, 9, 5, 7, 1));
    expect(value.personalizationReady, isTrue);
    expect(() => value.interests.clear(), throwsUnsupportedError);
  });

  test('skipping keeps completion and personalization independent', () {
    final value = UserPreferencesModel.fromJson({
      ..._payload(),
      'onboarding_completed': true,
    }).toDomain();
    expect(value.onboardingCompleted, isTrue);
    expect(value.personalizationReady, isFalse);
  });

  test('all response keys are required even when nullable', () {
    for (final key in _payload().keys) {
      expect(
        () => UserPreferencesModel.fromJson(_payload()..remove(key)),
        throwsFormatException,
        reason: key,
      );
    }
  });

  test('rejects duplicate, excessive and unknown interests', () {
    for (final interests in <Object?>[
      ['hiking', 'hiking'],
      ['hiking', 'photography', 'nightlife', 'wellness', 'history', 'wildlife'],
      ['unknown'],
      null,
      'hiking',
    ]) {
      expect(
        () => UserPreferencesModel.fromJson({
          ..._payload(),
          'interests': interests,
        }),
        throwsFormatException,
      );
    }
  });

  test('rejects malformed enum, boolean, location and timestamp fields', () {
    for (final entry in <String, Object?>{
      'travel_style': 'unknown',
      'budget_tier': 1,
      'trip_pace': 'fast',
      'recommendation_scope': null,
      'home_location': <String, Object?>{},
      'onboarding_completed': 'true',
      'personalization_ready': 1,
      'updated_at': '2026-09-05',
    }.entries) {
      expect(
        () => UserPreferencesModel.fromJson({
          ..._payload(),
          entry.key: entry.value,
        }),
        throwsFormatException,
        reason: entry.key,
      );
    }
  });
}
