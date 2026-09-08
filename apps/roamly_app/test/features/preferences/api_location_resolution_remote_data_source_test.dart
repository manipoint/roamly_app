import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/data/sources/api_location_resolution_remote_data_source.dart';
import 'package:roamly_networking/roamly_networking.dart';

Map<String, Object?> _location() => <String, Object?>{
  'provider': 'google',
  'provider_location_id': 'lahore-id',
  'canonical_name': 'Lahore, Punjab, Pakistan',
  'country_code': 'PK',
  'latitude': 31.5204,
  'longitude': 74.3587,
};

Map<String, Object?> _response({String query = 'Lahore'}) => <String, Object?>{
  'query': query,
  'options': <Object?>[_location()],
};

String _queryOfLength(int length) => List<String>.filled(length, 'x').join();

final class _Client implements ApiClient {
  Object? response = _response();
  Object? error;
  String? path;
  Map<String, Object?>? queryParameters;
  int calls = 0;

  @override
  Future<Object?> get(
    String path, {
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  }) async {
    calls++;
    this.path = path;
    this.queryParameters = queryParameters;
    if (error case final value?) throw value;
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Client client;
  late ApiLocationResolutionRemoteDataSource source;

  setUp(() {
    client = _Client();
    source = ApiLocationResolutionRemoteDataSource(apiClient: client);
  });

  test('trims the query and sends one bounded GET request', () async {
    final result = await source.resolve(query: '  Lahore  ', limit: 3);

    expect(client.calls, 1);
    expect(client.path, 'locations/resolve');
    expect(client.queryParameters, <String, Object?>{
      'query': 'Lahore',
      'limit': 3,
    });
    expect(result.query, 'Lahore');
    expect(result.options.single.canonicalName, 'Lahore, Punjab, Pakistan');
  });

  test('rejects invalid query lengths without making a request', () async {
    for (final query in <String>['', ' ', 'L', _queryOfLength(121)]) {
      await expectLater(
        source.resolve(query: query),
        throwsA(isA<ArgumentError>()),
      );
    }

    expect(client.calls, 0);
  });

  test('rejects invalid limits without making a request', () async {
    final validQuery = _queryOfLength(120);

    for (final limit in <int>[0, 6]) {
      await expectLater(
        source.resolve(query: validQuery, limit: limit),
        throwsA(isA<RangeError>()),
      );
    }

    expect(client.calls, 0);
  });

  test('rejects a response for a different normalized query', () async {
    final query = _queryOfLength(120);
    client.response = _response(query: 'Different place');

    await expectLater(source.resolve(query: query), throwsFormatException);
    expect(client.calls, 1);
  });

  test('rejects malformed response roots', () async {
    final query = _queryOfLength(120);

    for (final response in <Object?>[
      null,
      <Object?>[],
      'invalid',
      <String, Object?>{},
    ]) {
      client.response = response;
      await expectLater(source.resolve(query: query), throwsFormatException);
    }

    expect(client.calls, 4);
  });

  test('propagates transport errors without retrying', () async {
    final query = _queryOfLength(120);
    final error = Exception('transport failure');
    client.error = error;

    await expectLater(source.resolve(query: query), throwsA(same(error)));
    expect(client.calls, 1);
  });
}
