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

  group('SignInUseCase', () {
    test('uses the current device and normalized email to sign in', () async {
      final repository = _FakeAuthRepository(Success<AuthUser>(user));
      final deviceProvider = _FakeDeviceIdentityProvider(
        const Success<AuthDevice>(device),
      );
      final useCase = SignInUseCase(
        authRepository: repository,
        deviceIdentityProvider: deviceProvider,
      );

      final result = await useCase(
        email: '  traveler@example.com  ',
        password: ' password-with-intentional-spaces ',
      );

      expect(result, isA<Success<AuthUser>>());
      expect((result as Success<AuthUser>).value, user);
      expect(deviceProvider.calls, 1);
      expect(repository.loginCalls, 1);
      expect(repository.receivedEmail, 'traveler@example.com');
      expect(repository.receivedPassword, ' password-with-intentional-spaces ');
      expect(repository.receivedDevice, device);
    });

    test('does not call repository when device identity fails', () async {
      const deviceFailure = AuthFailure.deviceIdentity();
      final repository = _FakeAuthRepository(Success<AuthUser>(user));
      final deviceProvider = _FakeDeviceIdentityProvider(
        const FailureResult<AuthDevice>(deviceFailure),
      );
      final useCase = SignInUseCase(
        authRepository: repository,
        deviceIdentityProvider: deviceProvider,
      );

      final result = await useCase(
        email: 'traveler@example.com',
        password: 'password',
      );

      expect(result, isA<FailureResult<AuthUser>>());
      expect((result as FailureResult<AuthUser>).failure, same(deviceFailure));
      expect(deviceProvider.calls, 1);
      expect(repository.loginCalls, 0);
    });

    test('preserves a repository failure', () async {
      const repositoryFailure = AuthFailure.sessionStorage();
      final repository = _FakeAuthRepository(
        const FailureResult<AuthUser>(repositoryFailure),
      );
      final useCase = SignInUseCase(
        authRepository: repository,
        deviceIdentityProvider: _FakeDeviceIdentityProvider(
          const Success<AuthDevice>(device),
        ),
      );

      final result = await useCase(
        email: 'traveler@example.com',
        password: 'password',
      );

      expect(result, isA<FailureResult<AuthUser>>());
      expect(
        (result as FailureResult<AuthUser>).failure,
        same(repositoryFailure),
      );
      expect(repository.loginCalls, 1);
    });
  });
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
  _FakeAuthRepository(this.loginResult);

  final Result<AuthUser> loginResult;
  int loginCalls = 0;
  String? receivedEmail;
  String? receivedPassword;
  AuthDevice? receivedDevice;

  @override
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
    required AuthDevice device,
  }) async {
    loginCalls++;
    receivedEmail = email;
    receivedPassword = password;
    receivedDevice = device;
    return loginResult;
  }

  @override
  Future<Result<void>> logout() {
    throw UnimplementedError();
  }

  @override
  Future<Result<AuthUser>> register({
    required String email,
    required String password,
    required AuthDevice device,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<AuthUser?>> restoreSession() {
    throw UnimplementedError();
  }
}
