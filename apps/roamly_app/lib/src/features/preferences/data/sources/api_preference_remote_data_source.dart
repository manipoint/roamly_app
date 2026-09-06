import 'package:roamly_networking/roamly_networking.dart';

import '../../domain/entities/canonical_location.dart';
import '../../domain/entities/preference_types.dart';
import '../api/preference_api_paths.dart';
import '../mappers/preference_enum_mapper.dart';
import '../models/canonical_location_model.dart';
import '../models/user_preferences_model.dart';
import 'preference_remote_data_source.dart';

/// Loads and updates preferences through an authenticated API client.
///
/// HTTP and parsing failures propagate to the repository.
/// This adapter does not perform retries or cache account data.
final class ApiPreferenceRemoteDataSource
    implements PreferenceRemoteDataSource {
  const ApiPreferenceRemoteDataSource({required ApiClient authenticatedClient})
    : _client = authenticatedClient;

  final ApiClient _client;

  @override
  Future<UserPreferencesModel> getPreferences() async {
    final response = await _client.get(PreferenceApiPaths.preferences);

    return _parseResponse(response);
  }

  @override
  Future<UserPreferencesModel> savePreferences({
    required TravelStyle travelStyle,
    required Set<TravelInterest> interests,
    required BudgetTier budgetTier,
    required TripPace tripPace,
    required RecommendationScope recommendationScope,
    required CanonicalLocation? homeLocation,
  }) async {
    // Stable ordering produces the same payload for equivalent selections.
    final serializedInterests =
        interests.map(PreferenceEnumMapper.interestToJson).toList()..sort();

    final payload = <String, Object?>{
      'travel_style': PreferenceEnumMapper.travelStyleToJson(travelStyle),
      'interests': serializedInterests,
      'budget_tier': PreferenceEnumMapper.budgetTierToJson(budgetTier),
      'trip_pace': PreferenceEnumMapper.tripPaceToJson(tripPace),
      'recommendation_scope': PreferenceEnumMapper.recommendationScopeToJson(
        recommendationScope,
      ),
      'home_location': homeLocation == null
          ? null
          : CanonicalLocationModel.fromDomain(homeLocation).toJson(),
    };

    final response = await _client.put(
      PreferenceApiPaths.preferences,
      data: payload,
    );

    return _parseResponse(response);
  }

  @override
  Future<UserPreferencesModel> skipOnboarding() async {
    final response = await _client.post(PreferenceApiPaths.skipOnboarding);

    return _parseResponse(response);
  }

  static UserPreferencesModel _parseResponse(Object? response) {
    final reader = JsonReader(<String, Object?>{'response': response});

    return UserPreferencesModel.fromJson(reader.object('response'));
  }
}
