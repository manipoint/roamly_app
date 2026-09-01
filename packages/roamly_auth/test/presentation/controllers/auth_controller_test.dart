import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_auth/roamly_auth.dart';
import 'package:roamly_core/roamly_core.dart';

void main() {
  const device = AuthDevice(id: 'installation-1', name: 'iPhone');
  final user = AuthUser(
    id: 'user-1',
    email: 'traveler@example.com',
    status: AuthUserStatus.active,
    createdAt: DateTime.utc(2026, 9, 1),
  );

  group('AuthController', () {
    test('restores an authenticated session during initialization', () async {
      final repository = _FakeAuthRepository(
        restoreResult: Success<AuthUser?>(user),
      );
      final container = _createContainer(repository: repository);
      addTearDown(container.dispose);

      final restoredUser = await container.read(authControllerProvider.future);

      expect(restoredUser, user);
      expect(repository.restoreCalls, 1);
      expect(container.read(authControllerProvider).value, user);
    });

    test('represents an absent stored session as unauthenticated', () async {
      final repository = _FakeAuthRepository();
      final container = _createContainer(repository: repository);
      addTearDown(container.dispose);

      final restoredUser = await container.read(authControllerProvider.future);

      expect(restoredUser, isNull);
      expect(container.read(authControllerProvider).hasValue, isTrue);
      expect(container.read(authControllerProvider).value, isNull);
    });

    test('does not automatically retry a failed session restore', () async {
      const failure = AuthFailure.sessionStorage();
      final repository = _FakeAuthRepository(
        restoreResult: const FailureResult<AuthUser?>(failure),
      );
      final container = _createContainer(repository: repository);
      addTearDown(container.dispose);

      await expectLater(
        container.read(authControllerProvider.future),
        throwsA(same(failure)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(repository.restoreCalls, 1);
      expect(container.read(authControllerProvider).error, same(failure));
    });

    test('signs in and publishes the authenticated user', () async {
      final repository = _FakeAuthRepository(
        loginResult: Success<AuthUser>(user),
      );
      final deviceProvider = _FakeDeviceIdentityProvider(
        const Success<AuthDevice>(device),
      );
      final container = _createContainer(
        repository: repository,
        deviceProvider: deviceProvider,
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);

      await container
          .read(authControllerProvider.notifier)
          .signIn(email: ' traveler@example.com ', password: 'password');

      expect(repository.loginCalls, 1);
      expect(repository.receivedEmail, 'traveler@example.com');
      expect(repository.receivedDevice, device);
      expect(container.read(authControllerProvider).value, user);
    });

    test('publishes an authentication failure as AsyncError', () async {
      const failure = AuthFailure.sessionStorage();
      final repository = _FakeAuthRepository(
        loginResult: const FailureResult<AuthUser>(failure),
      );
      final container = _createContainer(repository: repository);
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);

      await container
          .read(authControllerProvider.notifier)
          .signIn(email: 'traveler@example.com', password: 'password');

      expect(container.read(authControllerProvider).error, same(failure));
    });

    test('blocks a duplicate authentication request while loading', () async {
      final pendingLogin = Completer<Result<AuthUser>>();
      final repository = _FakeAuthRepository(pendingLogin: pendingLogin);
      final deviceProvider = _FakeDeviceIdentityProvider(
        const Success<AuthDevice>(device),
      );
      final container = _createContainer(
        repository: repository,
        deviceProvider: deviceProvider,
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);
      final controller = container.read(authControllerProvider.notifier);

      final firstRequest = controller.signIn(
        email: 'traveler@example.com',
        password: 'password',
      );
      await Future<void>.delayed(Duration.zero);
      expect(container.read(authControllerProvider).isLoading, isTrue);

      await controller.signIn(
        email: 'traveler@example.com',
        password: 'password',
      );
      expect(repository.loginCalls, 1);
      expect(deviceProvider.calls, 1);

      pendingLogin.complete(Success<AuthUser>(user));
      await firstRequest;
      expect(container.read(authControllerProvider).value, user);
    });

    test('registers a user through the registration workflow', () async {
      final repository = _FakeAuthRepository(
        registerResult: Success<AuthUser>(user),
      );
      final container = _createContainer(repository: repository);
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);

      await container
          .read(authControllerProvider.notifier)
          .register(email: ' traveler@example.com ', password: 'password');

      expect(repository.registerCalls, 1);
      expect(repository.receivedEmail, 'traveler@example.com');
      expect(container.read(authControllerProvider).value, user);
    });

    test('logs out and publishes an unauthenticated session', () async {
      final repository = _FakeAuthRepository(
        restoreResult: Success<AuthUser?>(user),
      );
      final container = _createContainer(repository: repository);
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);

      await container.read(authControllerProvider.notifier).logout();

      expect(repository.logoutCalls, 1);
      expect(container.read(authControllerProvider).hasValue, isTrue);
      expect(container.read(authControllerProvider).value, isNull);
    });

    test('publishes a logout failure as AsyncError', () async {
      const failure = AuthFailure.sessionStorage();
      final repository = _FakeAuthRepository(
        restoreResult: Success<AuthUser?>(user),
        logoutResult: const FailureResult<void>(failure),
      );
      final container = _createContainer(repository: repository);
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);

      await container.read(authControllerProvider.notifier).logout();

      expect(repository.logoutCalls, 1);
      expect(container.read(authControllerProvider).error, same(failure));
    });
  });
}

ProviderContainer _createContainer({
  required _FakeAuthRepository repository,
  _FakeDeviceIdentityProvider? deviceProvider,
}) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      deviceIdentityProvider.overrideWithValue(
        deviceProvider ??
            _FakeDeviceIdentityProvider(
              const Success<AuthDevice>(AuthDevice(id: 'installation-1')),
            ),
      ),
    ],
  );
}

final class _FakeDeviceIdentityProvider implements DeviceIdentityProvider {
  _FakeDeviceIdentityProvider(this.result);

  final Result<AuthDevice> result;
  int calls = 0;

  @override
  Future<Result<AuthDevice>> getCurrentDevice() async {
    calls++;
    return result;
  }
}

final class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.restoreResult = const Success<AuthUser?>(null),
    this.loginResult,
    this.registerResult,
    this.logoutResult = const Success<void>(null),
    this.pendingLogin,
  });

  final Result<AuthUser?> restoreResult;
  final Result<AuthUser>? loginResult;
  final Result<AuthUser>? registerResult;
  final Result<void> logoutResult;
  final Completer<Result<AuthUser>>? pendingLogin;

  int restoreCalls = 0;
  int loginCalls = 0;
  int registerCalls = 0;
  int logoutCalls = 0;
  String? receivedEmail;
  AuthDevice? receivedDevice;

  @override
  Future<Result<AuthUser?>> restoreSession() async {
    restoreCalls++;
    return restoreResult;
  }

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
    required AuthDevice device,
  }) async {
    loginCalls++;
    receivedEmail = email;
    receivedDevice = device;
    if (pendingLogin case final pending?) {
      return pending.future;
    }
    return loginResult ??
        const FailureResult<AuthUser>(AuthFailure.sessionStorage());
  }

  @override
  Future<Result<AuthUser>> register({
    required String email,
    required String password,
    required AuthDevice device,
  }) async {
    registerCalls++;
    receivedEmail = email;
    receivedDevice = device;
    return registerResult ??
        const FailureResult<AuthUser>(AuthFailure.sessionStorage());
  }

  @override
  Future<Result<void>> logout() async {
    logoutCalls++;
    return logoutResult;
  }
}
