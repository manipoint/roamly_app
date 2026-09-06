import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/data/sources/api_preference_remote_data_source.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/canonical_location.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';
import 'package:roamly_networking/roamly_networking.dart';

Map<String, Object?> _response() => {
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
};

final class _Client implements ApiClient {
  Object? response = _response();
  Exception? error;
  String? method;
  String? path;
  Object? body;
  int calls = 0;

  Future<Object?> _request(String verb, String url, Object? data) async {
    calls++;
    method = verb;
    path = url;
    body = data;
    if (error case final failure?) throw failure;
    return response;
  }

  @override
  Future<Object?> get(
    String path, {
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  }) => _request('GET', path, null);

  @override
  Future<Object?> post(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  }) => _request('POST', path, data);

  @override
  Future<Object?> put(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  }) => _request('PUT', path, data);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Client client;
  late ApiPreferenceRemoteDataSource source;
  setUp(() {
    client = _Client();
    source = ApiPreferenceRemoteDataSource(authenticatedClient: client);
  });

  Future<void> save({CanonicalLocation? homeLocation}) async {
    await source.savePreferences(
      travelStyle: TravelStyle.nature,
      interests: {TravelInterest.localCulture, TravelInterest.hiking},
      budgetTier: BudgetTier.midRange,
      tripPace: TripPace.balanced,
      recommendationScope: RecommendationScope.both,
      homeLocation: homeLocation,
    );
  }

  test(
    'GET awaits and parses preferences using the relative endpoint',
    () async {
      final result = await source.getPreferences();
      expect(result.toDomain().onboardingCompleted, isTrue);
      expect(client.method, 'GET');
      expect(client.path, 'users/me/preferences');
      expect(client.calls, 1);
    },
  );

  test(
    'PUT serializes enums, sorted interests and explicit null location',
    () async {
      await save();
      expect(client.method, 'PUT');
      expect(client.path, 'users/me/preferences');
      expect(client.calls, 1);
      expect(client.body, {
        'travel_style': 'nature',
        'interests': ['hiking', 'local_culture'],
        'budget_tier': 'mid_range',
        'trip_pace': 'balanced',
        'recommendation_scope': 'both',
        'home_location': null,
      });
    },
  );

  test('PUT serializes canonical location without domain objects', () async {
    await save(
      homeLocation: const CanonicalLocation(
        provider: 'google',
        providerLocationId: 'lahore-id',
        canonicalName: 'Lahore, Pakistan',
        countryCode: 'PK',
        latitude: 31.5,
        longitude: 74.3,
      ),
    );
    expect((client.body as Map)['home_location'], {
      'provider': 'google',
      'provider_location_id': 'lahore-id',
      'canonical_name': 'Lahore, Pakistan',
      'country_code': 'PK',
      'latitude': 31.5,
      'longitude': 74.3,
    });
  });

  test('skip POST has no preference payload and parses server state', () async {
    final result = await source.skipOnboarding();
    expect(client.method, 'POST');
    expect(client.path, 'users/me/onboarding/skip');
    expect(client.body, isNull);
    expect(result.toDomain().onboardingCompleted, isTrue);
    expect(result.toDomain().personalizationReady, isFalse);
  });

  test('malformed response roots are rejected', () async {
    for (final value in <Object?>[
      null,
      [],
      'invalid',
      {1: 'value'},
      {},
    ]) {
      client.response = value;
      await expectLater(source.skipOnboarding(), throwsFormatException);
    }
  });

  test('transport exceptions propagate without retries on skip', () async {
    final error = Exception('transport failure');
    client.error = error;
    await expectLater(source.skipOnboarding(), throwsA(same(error)));
    expect(client.calls, 1);
  });
}
