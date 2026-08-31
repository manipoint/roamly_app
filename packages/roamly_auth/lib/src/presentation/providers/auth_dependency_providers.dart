import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_auth/roamly_auth.dart';

/// Repository dependency supplied by the application composition root.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw StateError(
    'authRepositoryProvider must be overridden by the application,',
  );
});

/// Device identity dependency supplied by the application composition root.
final deviceIdentityProvider = Provider<DeviceIdentityProvider>(
  ((ref) => throw StateError(
    'deviceIdentityProvider must be overridden by the application',
  )),
);

/// Signs users in using the configured repository and device identity.
final signInUseCaseProvider = Provider<SignInUseCase>(((ref) {
  return SignInUseCase(
    authRepository: ref.watch(authRepositoryProvider),
    deviceIdentityProvider: ref.watch(deviceIdentityProvider),
  );
}));

/// Registers users using the configured repository and device identity.
final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(
    authRepository: ref.watch(authRepositoryProvider),
    deviceIdentityProvider: ref.watch(deviceIdentityProvider),
  );
});
