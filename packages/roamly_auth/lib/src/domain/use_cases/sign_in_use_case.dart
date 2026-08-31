import 'package:roamly_core/roamly_core.dart';

import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';
import '../services/device_identity_provider.dart';

/// Authenticates a user from the current Roamly app installation.
final class SignInUseCase {
  const SignInUseCase({
    required AuthRepository authRepository,
    required DeviceIdentityProvider deviceIdentityProvider,
  }) : _authRepository = authRepository,
       _deviceIdentityProvider = deviceIdentityProvider;

  final AuthRepository _authRepository;
  final DeviceIdentityProvider _deviceIdentityProvider;

  Future<Result<AuthUser>> call({
    required String email,
    required String password,
  }) async {
    final deviceResult = await _deviceIdentityProvider.getCurrentDevice();
    return deviceResult.fold(
      onSuccess: (device) {
        return _authRepository.login(
          email: email.trim(),
          password: password,
          device: device,
        );
      },
      onFailure: (failure) async {
        return FailureResult<AuthUser>(failure);
      },
    );
  }
}
