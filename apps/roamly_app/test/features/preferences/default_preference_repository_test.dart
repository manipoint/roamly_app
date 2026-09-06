import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/data/models/user_preferences_model.dart';
import 'package:roamly_app/src/features/preferences/data/repositories/default_preference_repository.dart';
import 'package:roamly_app/src/features/preferences/data/sources/preference_remote_data_source.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/canonical_location.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/user_preferences.dart';
import 'package:roamly_app/src/features/preferences/domain/failures/preference_failure.dart';
import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_networking/roamly_networking.dart';

final class _Source implements PreferenceRemoteDataSource {
  int calls = 0;
  Set<TravelInterest>? capturedInterests;
  CanonicalLocation? capturedLocation;
  Object? error;
  final response = UserPreferencesModel.fromJson({
    'travel_style': null,
    'interests': <String>[],
    'budget_tier': null,
    'trip_pace': null,
    'recommendation_scope': 'both',
    'home_location': null,
    'onboarding_completed': true,
    'personalization_ready': false,
    'onboarding_completed_at': null,
    'created_at': null,
    'updated_at': null,
  });

  Future<UserPreferencesModel> _result() async {
    calls++;
    if (error case final failure?) throw failure;
    return response;
  }

  @override
  Future<UserPreferencesModel> getPreferences() => _result();
  @override
  Future<UserPreferencesModel> skipOnboarding() => _result();
  @override
  Future<UserPreferencesModel> savePreferences({
    required TravelStyle travelStyle,
    required Set<TravelInterest> interests,
    required BudgetTier budgetTier,
    required TripPace tripPace,
    required RecommendationScope recommendationScope,
    required CanonicalLocation? homeLocation,
  }) {
    capturedInterests = interests;
    capturedLocation = homeLocation;
    return _result();
  }
}

final class _Executor implements ApiRequestExecutor {
  AppFailure? failure;
  Future<void>? gate;
  int calls = 0;
  @override
  Future<Result<T>> execute<T>(Future<T> Function() request) async {
    calls++;
    if (failure case final value?) return FailureResult<T>(value);
    if (gate case final pending?) await pending;
    return Success<T>(await request());
  }
}

void main() {
  late _Source source;
  late _Executor executor;
  late DefaultPreferenceRepository repository;
  setUp(() {
    source = _Source();
    executor = _Executor();
    repository = DefaultPreferenceRepository(
      remoteDataSource: source,
      requestExecutor: executor,
    );
  });

  Future<Result<UserPreferences>> save({
    Set<TravelInterest>? interests,
    RecommendationScope scope = RecommendationScope.both,
    CanonicalLocation? location,
  }) => repository.savePreferences(
    travelStyle: TravelStyle.nature,
    interests: interests ?? {TravelInterest.hiking},
    budgetTier: BudgetTier.budget,
    tripPace: TripPace.relaxed,
    recommendationScope: scope,
    homeLocation: location,
  );

  void expectFailure(
    Result<UserPreferences> result,
    PreferenceFailureKind kind,
  ) {
    expect(result, isA<FailureResult<UserPreferences>>());
    expect(
      ((result as FailureResult<UserPreferences>).failure as PreferenceFailure)
          .kind,
      kind,
    );
  }

  test('get, save and skip return server-confirmed state', () async {
    for (final result in [
      await repository.getPreferences(),
      await save(),
      await repository.skipOnboarding(),
    ]) {
      expect(
        (result as Success<UserPreferences>).value,
        same(source.response.toDomain()),
      );
    }
    expect(source.calls, 3);
  });

  test('invalid interest counts do not invoke executor or source', () async {
    for (final values in [
      <TravelInterest>{},
      TravelInterest.values.take(6).toSet(),
    ]) {
      expectFailure(
        await save(interests: values),
        PreferenceFailureKind.invalidInterestCount,
      );
    }
    expect(executor.calls, 0);
    expect(source.calls, 0);
  });

  test('geographic scopes require home before network work', () async {
    for (final scope in [
      RecommendationScope.local,
      RecommendationScope.international,
    ]) {
      expectFailure(
        await save(scope: scope),
        PreferenceFailureKind.homeLocationRequired,
      );
    }
    expect(executor.calls, 0);
  });

  test('invalid outgoing location is not an invalid response', () async {
    expectFailure(
      await save(
        location: const CanonicalLocation(
          provider: 'google',
          providerLocationId: 'id',
          canonicalName: 'Lahore',
          countryCode: 'PK',
          latitude: 91,
          longitude: 74,
        ),
      ),
      PreferenceFailureKind.invalidHomeLocation,
    );
    expect(executor.calls, 0);
  });

  test('normalized location is forwarded to the remote source', () async {
    await save(
      location: const CanonicalLocation(
        provider: ' GOOGLE ',
        providerLocationId: ' id ',
        canonicalName: ' Lahore ',
        countryCode: 'pk',
        latitude: 31,
        longitude: 74,
      ),
    );
    expect(source.capturedLocation?.provider, 'google');
    expect(source.capturedLocation?.countryCode, 'PK');
    expect(source.capturedLocation?.canonicalName, 'Lahore');
  });

  test('captures immutable interests before asynchronous execution', () async {
    final gate = Completer<void>();
    executor.gate = gate.future;
    final interests = {TravelInterest.hiking};
    final pending = save(interests: interests);
    interests.clear();
    gate.complete();
    await pending;
    expect(source.capturedInterests, {TravelInterest.hiking});
    expect(() => source.capturedInterests!.clear(), throwsUnsupportedError);
  });

  test(
    'response format errors become safe failures for every operation',
    () async {
      source.error = const FormatException('malformed response');
      for (final result in [
        await repository.getPreferences(),
        await save(),
        await repository.skipOnboarding(),
      ]) {
        expectFailure(result, PreferenceFailureKind.invalidResponse);
      }
    },
  );

  test('executor failures are preserved unchanged', () async {
    const failure = NetworkFailure(
      code: 'unauthorized',
      isRetryable: false,
      kind: NetworkFailureKind.unauthorized,
      statusCode: 401,
    );
    executor.failure = failure;
    for (final result in [
      await repository.getPreferences(),
      await save(),
      await repository.skipOnboarding(),
    ]) {
      expect((result as FailureResult<UserPreferences>).failure, same(failure));
    }
    expect(source.calls, 0);
  });

  test('programming errors are not disguised as expected failures', () async {
    final error = StateError('bug');
    source.error = error;
    await expectLater(repository.getPreferences(), throwsA(same(error)));
  });
}
