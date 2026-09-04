import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_auth/src/data/models/auth_token_pair_model.dart';
import 'package:roamly_auth/src/data/models/auth_user_model.dart';
import 'package:roamly_auth/src/data/models/authentication_response_model.dart';
import 'package:roamly_auth/src/data/repositories/default_auth_repository.dart';
import 'package:roamly_auth/src/data/sources/auth_remote_data_source.dart';
import 'package:roamly_auth/src/data/storage/auth_token_store.dart';
import 'package:roamly_auth/roamly_auth.dart';
import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_logging/roamly_logging.dart';
import 'package:roamly_networking/roamly_networking.dart';

void main() {
  group('DefaultAuthRepository', () {
    test(
      'register forwards credentials, stores tokens, and returns user',
      () async {
        final remote = _FakeAuthRemoteDataSource();
        final tokenStore = _FakeAuthTokenStore();
        final repository = _repository(remote: remote, tokenStore: tokenStore);
        const device = AuthDevice(id: 'installation-1', name: 'iPhone');

        final result = await repository.register(
          email: 'traveler@example.com',
          password: 'safe-password',
          device: device,
        );

        final user = _successValue(result);
        expect(user.email, 'traveler@example.com');
        expect(remote.registerCalls, 1);
        expect(remote.receivedEmail, 'traveler@example.com');
        expect(remote.receivedPassword, 'safe-password');
        expect(remote.receivedDevice, device);
        expect(tokenStore.writeCalls, 1);
        expect(tokenStore.writtenTokens, same(remote.response.tokens));
      },
    );

    test(
      'login forwards credentials, stores tokens, and returns user',
      () async {
        final remote = _FakeAuthRemoteDataSource();
        final tokenStore = _FakeAuthTokenStore();
        final repository = _repository(remote: remote, tokenStore: tokenStore);
        const device = AuthDevice(id: 'installation-2');

        final result = await repository.login(
          email: 'traveler@example.com',
          password: 'safe-password',
          device: device,
        );

        expect(_successValue(result).status, AuthUserStatus.active);
        expect(remote.loginCalls, 1);
        expect(remote.receivedDevice, device);
        expect(tokenStore.writeCalls, 1);
      },
    );

    test(
      'login preserves a mapped remote failure and does not store tokens',
      () async {
        final remote = _FakeAuthRemoteDataSource(error: _connectionFailure());
        final tokenStore = _FakeAuthTokenStore();
        final repository = _repository(remote: remote, tokenStore: tokenStore);

        final result = await repository.login(
          email: 'traveler@example.com',
          password: 'safe-password',
          device: const AuthDevice(id: 'installation-1'),
        );

        final failure = _failureValue(result) as NetworkFailure;
        expect(failure.kind, NetworkFailureKind.connection);
        expect(tokenStore.writeCalls, 0);
      },
    );

    test('login maps token persistence failure to AuthFailure', () async {
      final tokenStore = _FakeAuthTokenStore(
        writeError: Exception('storage unavailable'),
      );
      final repository = _repository(
        remote: _FakeAuthRemoteDataSource(),
        tokenStore: tokenStore,
      );

      final result = await repository.login(
        email: 'traveler@example.com',
        password: 'safe-password',
        device: const AuthDevice(id: 'installation-1'),
      );

      final failure = _failureValue(result) as AuthFailure;
      expect(failure.kind, AuthFailureKind.sessionStorage);
    });

    test('restore returns successful null when no tokens exist', () async {
      final remote = _FakeAuthRemoteDataSource();
      final tokenStore = _FakeAuthTokenStore();
      final repository = _repository(remote: remote, tokenStore: tokenStore);

      final result = await repository.restoreSession();

      expect(_successValue(result), isNull);
      expect(tokenStore.readCalls, 1);
      expect(remote.refreshCalls, 0);
    });

    test('restore refreshes session and persists rotated tokens', () async {
      final storedTokens = _tokens(accessToken: 'old-access');
      final remote = _FakeAuthRemoteDataSource();
      final tokenStore = _FakeAuthTokenStore(tokens: storedTokens);
      final repository = _repository(remote: remote, tokenStore: tokenStore);

      final result = await repository.restoreSession();

      expect(_successValue(result)?.email, 'traveler@example.com');
      expect(remote.receivedRefreshToken, storedTokens.refreshToken);
      expect(tokenStore.writeCalls, 1);
      expect(tokenStore.writtenTokens, same(remote.response.tokens));
    });

    test(
      'unauthorized refresh clears tokens and returns signed-out state',
      () async {
        final remote = _FakeAuthRemoteDataSource(error: _unauthorizedFailure());
        final tokenStore = _FakeAuthTokenStore(tokens: _tokens());
        final repository = _repository(remote: remote, tokenStore: tokenStore);

        final result = await repository.restoreSession();

        expect(_successValue(result), isNull);
        expect(tokenStore.clearCalls, 1);
        expect(tokenStore.tokens, isNull);
      },
    );

    test('non-unauthorized refresh failure preserves stored tokens', () async {
      final storedTokens = _tokens();
      final remote = _FakeAuthRemoteDataSource(error: _connectionFailure());
      final tokenStore = _FakeAuthTokenStore(tokens: storedTokens);
      final repository = _repository(remote: remote, tokenStore: tokenStore);

      final result = await repository.restoreSession();

      final failure = _failureValue(result) as NetworkFailure;
      expect(failure.kind, NetworkFailureKind.connection);
      expect(tokenStore.clearCalls, 0);
      expect(tokenStore.tokens, same(storedTokens));
    });

    test('restore maps secure-token read failure to AuthFailure', () async {
      final remote = _FakeAuthRemoteDataSource();
      final tokenStore = _FakeAuthTokenStore(
        readError: Exception('storage unavailable'),
      );
      final repository = _repository(remote: remote, tokenStore: tokenStore);

      final result = await repository.restoreSession();

      final failure = _failureValue(result) as AuthFailure;
      expect(failure.kind, AuthFailureKind.sessionStorage);
      expect(remote.refreshCalls, 0);
    });

    test('restore clears corrupted persisted tokens and signs out', () async {
      final remote = _FakeAuthRemoteDataSource();
      final tokenStore = _FakeAuthTokenStore(
        readError: const FormatException('corrupted tokens'),
      );
      final repository = _repository(remote: remote, tokenStore: tokenStore);

      final result = await repository.restoreSession();

      expect(_successValue(result), isNull);
      expect(tokenStore.clearCalls, 1);
      expect(remote.refreshCalls, 0);
    });

    test(
      'restore reports storage failure when corrupted tokens cannot clear',
      () async {
        final tokenStore = _FakeAuthTokenStore(
          readError: const FormatException('corrupted tokens'),
          clearError: Exception('delete failed'),
        );
        final repository = _repository(
          remote: _FakeAuthRemoteDataSource(),
          tokenStore: tokenStore,
        );

        final result = await repository.restoreSession();

        final failure = _failureValue(result) as AuthFailure;
        expect(failure.kind, AuthFailureKind.sessionStorage);
      },
    );

    test(
      'restore reports storage failure when rotated tokens cannot persist',
      () async {
        final tokenStore = _FakeAuthTokenStore(
          tokens: _tokens(),
          writeError: Exception('write failed'),
        );
        final repository = _repository(
          remote: _FakeAuthRemoteDataSource(),
          tokenStore: tokenStore,
        );

        final result = await repository.restoreSession();

        final failure = _failureValue(result) as AuthFailure;
        expect(failure.kind, AuthFailureKind.sessionStorage);
      },
    );

    test('logout calls remote endpoint and clears local tokens', () async {
      final remote = _FakeAuthRemoteDataSource();
      final tokenStore = _FakeAuthTokenStore(tokens: _tokens());
      final repository = _repository(remote: remote, tokenStore: tokenStore);

      final result = await repository.logout();

      expect(result, isA<Success<void>>());
      expect(remote.logoutCalls, 1);
      expect(tokenStore.clearCalls, 1);
      expect(tokenStore.tokens, isNull);
    });

    test('logout clears local tokens while returning remote failure', () async {
      final remote = _FakeAuthRemoteDataSource(error: _connectionFailure());
      final tokenStore = _FakeAuthTokenStore(tokens: _tokens());
      final repository = _repository(remote: remote, tokenStore: tokenStore);

      final result = await repository.logout();

      final failure = _failureValue(result) as NetworkFailure;
      expect(failure.kind, NetworkFailureKind.connection);
      expect(tokenStore.clearCalls, 1);
      expect(tokenStore.tokens, isNull);
    });

    test('logout storage failure takes priority over remote success', () async {
      final tokenStore = _FakeAuthTokenStore(
        tokens: _tokens(),
        clearError: Exception('delete failed'),
      );
      final repository = _repository(
        remote: _FakeAuthRemoteDataSource(),
        tokenStore: tokenStore,
      );

      final result = await repository.logout();

      final failure = _failureValue(result) as AuthFailure;
      expect(failure.kind, AuthFailureKind.sessionStorage);
    });

    test('does not hide programming errors raised by token storage', () async {
      final expectedError = StateError('invalid storage state');
      final repository = _repository(
        remote: _FakeAuthRemoteDataSource(),
        tokenStore: _FakeAuthTokenStore(writeError: expectedError),
      );

      await expectLater(
        repository.login(
          email: 'traveler@example.com',
          password: 'safe-password',
          device: const AuthDevice(id: 'installation-1'),
        ),
        throwsA(same(expectedError)),
      );
    });
  });
}

DefaultAuthRepository _repository({
  required _FakeAuthRemoteDataSource remote,
  required _FakeAuthTokenStore tokenStore,
}) {
  return DefaultAuthRepository(
    remoteDataSource: remote,
    tokenStore: tokenStore,
    requestExecutor: const _FakeApiRequestExecutor(),
    logger: RoamlyLogger(
      name: 'test.auth.repository',
      sink: const NoopLogSink(),
    ),
  );
}

T _successValue<T>(Result<T> result) {
  expect(result, isA<Success<T>>());
  return (result as Success<T>).value;
}

AppFailure _failureValue<T>(Result<T> result) {
  expect(result, isA<FailureResult<T>>());
  return (result as FailureResult<T>).failure;
}

final class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  _FakeAuthRemoteDataSource({AuthenticationResponseModel? response, this.error})
    : response = response ?? _authenticationResponse();

  final AuthenticationResponseModel response;
  final Object? error;
  int registerCalls = 0;
  int loginCalls = 0;
  int refreshCalls = 0;
  int logoutCalls = 0;
  String? receivedEmail;
  String? receivedPassword;
  AuthDevice? receivedDevice;
  String? receivedRefreshToken;

  @override
  Future<AuthenticationResponseModel> register({
    required String email,
    required String password,
    required AuthDevice device,
  }) async {
    registerCalls++;
    _recordCredentials(email: email, password: password, device: device);
    return _respond();
  }

  @override
  Future<AuthenticationResponseModel> login({
    required String email,
    required String password,
    required AuthDevice device,
  }) async {
    loginCalls++;
    _recordCredentials(email: email, password: password, device: device);
    return _respond();
  }

  @override
  Future<AuthenticationResponseModel> refresh({
    required String refreshToken,
  }) async {
    refreshCalls++;
    receivedRefreshToken = refreshToken;
    return _respond();
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (error case final error?) {
      throw error;
    }
  }

  AuthenticationResponseModel _respond() {
    if (error case final error?) {
      throw error;
    }
    return response;
  }

  void _recordCredentials({
    required String email,
    required String password,
    required AuthDevice device,
  }) {
    receivedEmail = email;
    receivedPassword = password;
    receivedDevice = device;
  }
}

final class _FakeAuthTokenStore implements AuthTokenStore {
  _FakeAuthTokenStore({
    this.tokens,
    this.readError,
    this.writeError,
    this.clearError,
  });

  AuthTokenPairModel? tokens;
  final Object? readError;
  final Object? writeError;
  final Object? clearError;
  int readCalls = 0;
  int writeCalls = 0;
  int clearCalls = 0;
  AuthTokenPairModel? writtenTokens;

  @override
  Future<AuthTokenPairModel?> readTokens() async {
    readCalls++;
    if (readError case final error?) {
      throw error;
    }
    return tokens;
  }

  @override
  Future<String?> readAccessToken() async {
    return (await readTokens())?.accessToken;
  }

  @override
  Future<void> writeTokens(AuthTokenPairModel tokens) async {
    writeCalls++;
    if (writeError case final error?) {
      throw error;
    }
    writtenTokens = tokens;
    this.tokens = tokens;
  }

  @override
  Future<void> clearTokens() async {
    clearCalls++;
    if (clearError case final error?) {
      throw error;
    }
    tokens = null;
  }
}

AuthenticationResponseModel _authenticationResponse() {
  return AuthenticationResponseModel(
    user: AuthUserModel(
      id: '2db19db1-81b7-467c-b0e1-05bce783522a',
      email: 'traveler@example.com',
      status: 'active',
      createdAt: DateTime.utc(2026, 8, 30, 10, 30),
    ),
    tokens: _tokens(accessToken: 'rotated-access'),
  );
}

AuthTokenPairModel _tokens({String accessToken = 'stored-access'}) {
  return AuthTokenPairModel(
    accessToken: accessToken,
    refreshToken: 'stored-refresh',
    tokenType: 'bearer',
    accessTokenExpiresAt: DateTime.utc(2026, 8, 30, 10, 45),
    refreshTokenExpiresAt: DateTime.utc(2026, 9, 29, 10, 30),
  );
}

NetworkFailure _connectionFailure() {
  return const NetworkFailure(
    code: 'network_connection_failed',
    isRetryable: true,
    kind: NetworkFailureKind.connection,
  );
}

NetworkFailure _unauthorizedFailure() {
  return const NetworkFailure(
    code: 'unauthorized',
    isRetryable: false,
    kind: NetworkFailureKind.unauthorized,
    statusCode: 401,
  );
}

final class _FakeApiRequestExecutor implements ApiRequestExecutor {
  const _FakeApiRequestExecutor();

  @override
  Future<Result<T>> execute<T>(Future<T> Function() request) async {
    try {
      return Success<T>(await request());
    } on NetworkFailure catch (failure) {
      return FailureResult<T>(failure);
    }
  }
}
