import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_auth/src/data/api/auth_api_paths.dart';
import 'package:roamly_auth/src/data/sources/api_auth_remote_data_source.dart';
import 'package:roamly_auth/roamly_auth.dart';
import 'package:roamly_networking/roamly_networking.dart';

void main() {
  group('ApiAuthRemoteDataSource', () {
    test('register uses public client and includes the device name', () async {
      final publicClient = _RecordingApiClient(
        responseData: _authenticationJson(),
      );
      final authenticatedClient = _RecordingApiClient();
      final dataSource = ApiAuthRemoteDataSource(
        publicClient: publicClient,
        authenticatedClient: authenticatedClient,
      );

      final response = await dataSource.register(
        email: 'traveler@example.com',
        password: 'safe-password',
        device: const AuthDevice(id: 'installation-1', name: 'iPhone'),
      );

      expect(publicClient.requests, hasLength(1));
      expect(publicClient.requests.single.method, 'POST');
      expect(publicClient.requests.single.path, AuthApiPaths.register);
      expect(publicClient.requests.single.data, <String, Object?>{
        'email': 'traveler@example.com',
        'password': 'safe-password',
        'device_id': 'installation-1',
        'device_name': 'iPhone',
      });
      expect(authenticatedClient.requests, isEmpty);
      expect(response.user.email, 'traveler@example.com');
      expect(response.tokens.accessToken, 'access-secret');
    });

    test('register omits a missing device name', () async {
      final publicClient = _RecordingApiClient(
        responseData: _authenticationJson(),
      );
      final dataSource = ApiAuthRemoteDataSource(
        publicClient: publicClient,
        authenticatedClient: _RecordingApiClient(),
      );

      await dataSource.register(
        email: 'traveler@example.com',
        password: 'safe-password',
        device: const AuthDevice(id: 'installation-1'),
      );

      expect(publicClient.requests.single.data, isNot(contains('device_name')));
    });

    test('login uses public client and parses the response', () async {
      final publicClient = _RecordingApiClient(
        responseData: _authenticationJson(),
      );
      final authenticatedClient = _RecordingApiClient();
      final dataSource = ApiAuthRemoteDataSource(
        publicClient: publicClient,
        authenticatedClient: authenticatedClient,
      );

      final response = await dataSource.login(
        email: 'traveler@example.com',
        password: 'safe-password',
        device: const AuthDevice(id: 'installation-1'),
      );

      expect(publicClient.requests.single.path, AuthApiPaths.login);
      expect(authenticatedClient.requests, isEmpty);
      expect(response.tokens.refreshToken, 'refresh-secret');
    });

    test('refresh uses public client and sends only refresh token', () async {
      final publicClient = _RecordingApiClient(
        responseData: _authenticationJson(),
      );
      final authenticatedClient = _RecordingApiClient();
      final dataSource = ApiAuthRemoteDataSource(
        publicClient: publicClient,
        authenticatedClient: authenticatedClient,
      );

      final response = await dataSource.refresh(refreshToken: 'refresh-secret');

      expect(publicClient.requests.single.path, AuthApiPaths.refresh);
      expect(publicClient.requests.single.data, <String, Object?>{
        'refresh_token': 'refresh-secret',
      });
      expect(authenticatedClient.requests, isEmpty);
      expect(response.tokens.accessToken, 'access-secret');
    });

    test('logout uses authenticated client', () async {
      final publicClient = _RecordingApiClient();
      final authenticatedClient = _RecordingApiClient();
      final dataSource = ApiAuthRemoteDataSource(
        publicClient: publicClient,
        authenticatedClient: authenticatedClient,
      );

      await dataSource.logout();

      expect(publicClient.requests, isEmpty);
      expect(authenticatedClient.requests, hasLength(1));
      expect(authenticatedClient.requests.single.method, 'POST');
      expect(authenticatedClient.requests.single.path, AuthApiPaths.logout);
      expect(authenticatedClient.requests.single.data, isNull);
    });

    test('rejects a successful non-object response', () async {
      final dataSource = ApiAuthRemoteDataSource(
        publicClient: _RecordingApiClient(responseData: <Object?>[]),
        authenticatedClient: _RecordingApiClient(),
      );

      await expectLater(
        dataSource.login(
          email: 'traveler@example.com',
          password: 'safe-password',
          device: const AuthDevice(id: 'installation-1'),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'Authentication response must be a JSON object',
          ),
        ),
      );
    });

    test('propagates client failures unchanged', () async {
      final expectedError = StateError('Request failed');
      final dataSource = ApiAuthRemoteDataSource(
        publicClient: _RecordingApiClient(error: expectedError),
        authenticatedClient: _RecordingApiClient(),
      );

      await expectLater(
        dataSource.login(
          email: 'traveler@example.com',
          password: 'safe-password',
          device: const AuthDevice(id: 'installation-1'),
        ),
        throwsA(same(expectedError)),
      );
    });
  });
}

final class _RecordedRequest {
  const _RecordedRequest({
    required this.method,
    required this.path,
    this.data,
    this.queryParameters,
    this.headers,
  });

  final String method;
  final String path;
  final Object? data;
  final Map<String, Object?>? queryParameters;
  final Map<String, Object?>? headers;
}

final class _RecordingApiClient implements ApiClient {
  _RecordingApiClient({this.responseData, this.error});

  final Object? responseData;
  final Object? error;
  final List<_RecordedRequest> requests = <_RecordedRequest>[];

  @override
  Future<Object?> delete(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  }) {
    return _record(
      method: 'DELETE',
      path: path,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  @override
  Future<Object?> get(
    String path, {
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  }) {
    return _record(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  @override
  Future<Object?> patch(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  }) {
    return _record(
      method: 'PATCH',
      path: path,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  @override
  Future<Object?> post(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  }) {
    return _record(
      method: 'POST',
      path: path,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  @override
  Future<Object?> put(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  }) {
    return _record(
      method: 'PUT',
      path: path,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<Object?> _record({
    required String method,
    required String path,
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  }) async {
    requests.add(
      _RecordedRequest(
        method: method,
        path: path,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
      ),
    );

    if (error case final error?) {
      throw error;
    }
    return responseData;
  }
}

Map<String, Object?> _authenticationJson() {
  return <String, Object?>{
    'user': <String, Object?>{
      'id': '2db19db1-81b7-467c-b0e1-05bce783522a',
      'email': 'traveler@example.com',
      'status': 'active',
      'created_at': '2026-08-30T10:30:00Z',
    },
    'tokens': <String, Object?>{
      'access_token': 'access-secret',
      'refresh_token': 'refresh-secret',
      'token_type': 'bearer',
      'access_token_expires_at': '2026-08-30T10:45:00Z',
      'refresh_token_expires_at': '2026-09-29T10:30:00Z',
    },
  };
}
