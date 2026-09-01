import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_core/roamly_core.dart';

import '../../domain/entities/auth_user.dart';
import '../providers/auth_dependency_providers.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
  retry: (_, _) => null,
);

final class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final result = await ref.watch(authRepositoryProvider).restoreSession();
    return result.fold(
      onSuccess: (user) => user,
      onFailure: (failure) => throw failure,
    );
  }

  Future<void> signIn({required String email, required String password}) {
    return _authenticate(
      () => ref.read(signInUseCaseProvider)(email: email, password: password),
    );
  }

  Future<void> register({required String email, required String password}) {
    return _authenticate(
      () => ref.read(registerUseCaseProvider)(email: email, password: password),
    );
  }

  Future<void> logout() async {
    if (state.isLoading) {
      return;
    }
    state = const AsyncLoading<AuthUser?>();
    state = await AsyncValue.guard<AuthUser?>(() async {
      final result = await ref.read(authRepositoryProvider).logout();
      return result.fold<AuthUser?>(
        onSuccess: (_) => null,
        onFailure: (failure) => throw failure,
      );
    });
  }

  Future<void> _authenticate(
    Future<Result<AuthUser>> Function() operation,
  ) async {
    if (state.isLoading) {
      return;
    }
    state = const AsyncLoading<AuthUser?>();
    state = await AsyncValue.guard<AuthUser?>(() async {
      final result = await operation();
      return result.fold<AuthUser?>(
        onSuccess: (user) => user,
        onFailure: (failure) => throw failure,
      );
    });
  }
}
