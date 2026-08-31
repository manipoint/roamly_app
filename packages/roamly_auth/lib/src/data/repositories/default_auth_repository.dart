// DefaultAuthRepository

import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_networking/roamly_networking.dart';

import '../sources/auth_remote_data_source.dart';
import '../storage/auth_token_store.dart';
import '../../domain/entities/auth_device.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_token_pair_model.dart';
import '../models/authentication_response_model.dart';

final class DefaultAuthRepository implements AuthRepository {
  const DefaultAuthRepository({
    required AuthRemoteDataSource remoteDataSource,
    required AuthTokenStore tokenStore,
    required ApiRequestExecutor requestExecutor,
  }) : _remoteDataSource = remoteDataSource,
       _tokenStore = tokenStore,
       _requestExecutor = requestExecutor;

  final AuthRemoteDataSource _remoteDataSource;
  final AuthTokenStore _tokenStore;
  final ApiRequestExecutor _requestExecutor;

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
    required AuthDevice device,
  }) {
    return _authenticate(
      () => _remoteDataSource.login(
        email: email,
        password: password,
        device: device,
      ),
    );
  }

  @override
  Future<Result<void>> logout() async {
    final remoteResult = await _requestExecutor.execute(
      _remoteDataSource.logout,
    );
    final storageFailure = await _clearTokensSafely();
    if (storageFailure != null) {
      return FailureResult<void>(storageFailure);
    }
    return remoteResult;
  }

  @override
  Future<Result<AuthUser>> register({
    required String email,
    required String password,
    required AuthDevice device,
  }) {
    return _authenticate(
      () => _remoteDataSource.register(
        email: email,
        password: password,
        device: device,
      ),
    );
  }

  @override
  Future<Result<AuthUser?>> restoreSession() async {
    final storedTokensResult = await _readTokens();

    if (storedTokensResult case FailureResult<AuthTokenPairModel?>(
      :final failure,
    )) {
      return FailureResult<AuthUser?>(failure);
    }
    final storedToken =
        (storedTokensResult as Success<AuthTokenPairModel?>).value;
    if (storedToken == null) {
      return const Success<AuthUser?>(null);
    }
    final refreshResult = await _requestExecutor
        .execute<AuthenticationResponseModel>(
          () =>
              _remoteDataSource.refresh(refreshToken: storedToken.refreshToken),
        );
    return refreshResult.fold(
      onSuccess: (response) async {
        final user = response.user.toDomain();
        final storageFailure = await _writeTokensSafely(response.tokens);
        if (storageFailure != null) {
          return FailureResult<AuthUser?>(storageFailure);
        }
        return Success<AuthUser?>(user);
      },
      onFailure: (failure) async {
        if (!_isUnauthorized(failure)) {
          return FailureResult<AuthUser>(failure);
        }
        final storageFailure = await _clearTokensSafely();
        if (storageFailure != null) {
          return FailureResult<AuthUser>(storageFailure);
        }
        return const Success<AuthUser?>(null);
      },
    );
  }

  Future<Result<AuthUser>> _authenticate(
    Future<AuthenticationResponseModel> Function() request,
  ) async {
    final result = await _requestExecutor.execute<AuthenticationResponseModel>(
      request,
    );

    return result.fold(
      onSuccess: (response) async {
        final user = response.user.toDomain();
        final storageFailure = await _writeTokensSafely(response.tokens);
        if (storageFailure != null) {
          return FailureResult<AuthUser>(storageFailure);
        }
        return Success<AuthUser>(user);
      },
      onFailure: (failure) async {
        return FailureResult<AuthUser>(failure);
      },
    );
  }

  Future<AuthFailure?> _writeTokensSafely(AuthTokenPairModel tokens) async {
    try {
      await _tokenStore.writeTokens(tokens);
      return null;
    } on Exception {
      return const AuthFailure.sessionStorage();
    }
  }

  Future<Result<AuthTokenPairModel?>> _readTokens() async {
    try {
      final tokens = await _tokenStore.readTokens();
      return Success<AuthTokenPairModel?>(tokens);
    } on FormatException {
      return _recoverFromCorruptedTokens();
    } on Exception {
      return const FailureResult<AuthTokenPairModel?>(
        AuthFailure.sessionStorage(),
      );
    }
  }

  Future<Result<AuthTokenPairModel?>> _recoverFromCorruptedTokens() async {
    final storageFailure = await _clearTokensSafely();
    if (storageFailure != null) {
      return FailureResult<AuthTokenPairModel?>(storageFailure);
    }
    return const Success<AuthTokenPairModel?>(null);
  }

  Future<AuthFailure?> _clearTokensSafely() async {
    try {
      await _tokenStore.clearTokens();
      return null;
    } on Exception {
      return const AuthFailure.sessionStorage();
    }
  }

  static bool _isUnauthorized(AppFailure failure) {
    return failure is NetworkFailure &&
        failure.kind == NetworkFailureKind.unauthorized;
  }
}
