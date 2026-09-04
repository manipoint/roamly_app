import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_logging/roamly_logging.dart';

import '../../domain/entities/auth_user.dart';
import '../providers/auth_dependency_providers.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
  retry: (_, _) => null,
);

final class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final logger = ref.read(authLoggerProvider);
    logger.debug('Session restoration started');
    late final Result<AuthUser?> result;
    try {
      result = await ref.watch(authRepositoryProvider).restoreSession();
    } on Object catch (error, stackTrace) {
      _logUnexpectedError(
        logger,
        operation: 'restore_session',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
    return result.fold(
      onSuccess: (user) {
        if (user == null) {
          logger.debug('No active session found');
        } else {
          logger.info('Session restored');
        }
        return user;
      },
      onFailure: (failure) {
        _logFailure(logger, operation: 'restore_session', failure: failure);
        throw failure;
      },
    );
  }

  Future<void> signIn({required String email, required String password}) {
    return _authenticate(
      () => ref.read(signInUseCaseProvider)(email: email, password: password),
      operationName: 'sign_in',
    );
  }

  Future<void> register({required String email, required String password}) {
    return _authenticate(
      () => ref.read(registerUseCaseProvider)(email: email, password: password),
      operationName: 'register',
    );
  }

  Future<void> logout() async {
    final logger = ref.read(authLoggerProvider);
    if (state.isLoading) {
      logger.debug(
        'Authentication operation ignored while busy',
        fields: {'operation': 'logout'},
      );
      return;
    }
    state = const AsyncLoading<AuthUser?>();
    state = await AsyncValue.guard<AuthUser?>(() async {
      late final Result<void> result;
      try {
        result = await ref.read(authRepositoryProvider).logout();
      } on Object catch (error, stackTrace) {
        _logUnexpectedError(
          logger,
          operation: 'logout',
          error: error,
          stackTrace: stackTrace,
        );
        rethrow;
      }
      return result.fold<AuthUser?>(
        onSuccess: (_) {
          logger.info('Signed out');
          return null;
        },
        onFailure: (failure) {
          _logFailure(logger, operation: 'logout', failure: failure);
          throw failure;
        },
      );
    });
  }

  Future<void> _authenticate(
    Future<Result<AuthUser>> Function() operation, {
    required String operationName,
  }) async {
    final logger = ref.read(authLoggerProvider);
    if (state.isLoading) {
      logger.debug(
        'Authentication operation ignored while busy',
        fields: {'operation': operationName},
      );
      return;
    }
    logger.debug(
      'Authentication operation started',
      fields: {'operation': operationName},
    );
    state = const AsyncLoading<AuthUser?>();
    state = await AsyncValue.guard<AuthUser?>(() async {
      late final Result<AuthUser> result;
      try {
        result = await operation();
      } on Object catch (error, stackTrace) {
        _logUnexpectedError(
          logger,
          operation: operationName,
          error: error,
          stackTrace: stackTrace,
        );
        rethrow;
      }
      return result.fold<AuthUser?>(
        onSuccess: (user) {
          logger.info(
            'Authentication operation completed',
            fields: {'operation': operationName},
          );
          return user;
        },
        onFailure: (failure) {
          _logFailure(logger, operation: operationName, failure: failure);
          throw failure;
        },
      );
    });
  }

  static void _logFailure(
    RoamlyLogger logger, {
    required String operation,
    required AppFailure failure,
  }) {
    logger.warning(
      'Authentication operation failed',
      fields: {
        'operation': operation,
        'failure_code': failure.code,
        'is_retryable': failure.isRetryable,
      },
    );
  }

  static void _logUnexpectedError(
    RoamlyLogger logger, {
    required String operation,
    required Object error,
    required StackTrace stackTrace,
  }) {
    logger.error(
      'Unexpected authentication error',
      fields: {
        'operation': operation,
        'error_type': error.runtimeType.toString(),
      },
      stackTrace: stackTrace,
    );
  }
}
