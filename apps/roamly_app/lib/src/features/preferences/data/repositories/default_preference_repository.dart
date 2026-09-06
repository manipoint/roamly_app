import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_networking/roamly_networking.dart';

import '../../domain/entities/canonical_location.dart';
import '../../domain/entities/preference_types.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/failures/preference_failure.dart';
import '../../domain/repositories/preference_repository.dart';
import '../models/canonical_location_model.dart';
import '../models/user_preferences_model.dart';
import '../sources/preference_remote_data_source.dart';

/// Validates preference selections and returns safe application results.
///
/// Does not cache account data, retry requests, or fabricate saved state.
final class DefaultPreferenceRepository implements PreferenceRepository {
  const DefaultPreferenceRepository({
    required PreferenceRemoteDataSource remoteDataSource,
    required ApiRequestExecutor requestExecutor,
  }) : _remoteDataSource = remoteDataSource,
       _requestExecutor = requestExecutor;

  final PreferenceRemoteDataSource _remoteDataSource;
  final ApiRequestExecutor _requestExecutor;

  @override
  Future<Result<UserPreferences>> getPreferences() {
    return _execute(_remoteDataSource.getPreferences);
  }

  @override
  Future<Result<UserPreferences>> savePreferences({
    required TravelStyle travelStyle,
    required Set<TravelInterest> interests,
    required BudgetTier budgetTier,
    required TripPace tripPace,
    required RecommendationScope recommendationScope,
    required CanonicalLocation? homeLocation,
  }) async {
    final selectedInterests = Set<TravelInterest>.unmodifiable(interests);

    if (selectedInterests.isEmpty || selectedInterests.length > 5) {
      return FailureResult<UserPreferences>(
        PreferenceFailure.invalidInterestCount(),
      );
    }

    if (recommendationScope.requiresHomeLocation && homeLocation == null) {
      return FailureResult<UserPreferences>(
        PreferenceFailure.homeLocationRequired(),
      );
    }

    CanonicalLocation? validatedLocation;

    try {
      if (homeLocation != null) {
        validatedLocation = CanonicalLocationModel.fromDomain(
          homeLocation,
        ).toDomain();
      }
    } on FormatException {
      return FailureResult<UserPreferences>(
        PreferenceFailure.invalidHomeLocation(),
      );
    }

    return _execute(
      () => _remoteDataSource.savePreferences(
        travelStyle: travelStyle,
        interests: selectedInterests,
        budgetTier: budgetTier,
        tripPace: tripPace,
        recommendationScope: recommendationScope,
        homeLocation: validatedLocation,
      ),
    );
  }

  @override
  Future<Result<UserPreferences>> skipOnboarding() {
    return _execute(_remoteDataSource.skipOnboarding);
  }

  /// Preserves transport failures and converts malformed response failures.
  Future<Result<UserPreferences>> _execute(
    Future<UserPreferencesModel> Function() request,
  ) async {
    try {
      return await _requestExecutor.execute<UserPreferences>(() async {
        final response = await request();
        return response.toDomain();
      });
    } on FormatException {
      return FailureResult<UserPreferences>(
        PreferenceFailure.invalidResponse(),
      );
    }
  }
}
