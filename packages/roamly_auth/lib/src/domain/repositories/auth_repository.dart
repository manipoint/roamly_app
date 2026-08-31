import 'package:roamly_core/roamly_core.dart';

import '../entities/auth_user.dart';
import '../entities/auth_device.dart';

/// Authentication operations available to the application layer.

abstract interface class AuthRepository {
  Future<Result<AuthUser>> register({
    required String email,
    required String password,
    required AuthDevice device,
  });
  Future<Result<AuthUser>> login({
    required String email,
    required String password,
    required AuthDevice device,
  });

  /// Restores a previously persisted authenticated session.
  ///
  /// Returns a successful null value when no local session exists.
  Future<Result<AuthUser?>> restoreSession();

  /// Ends only the current device session.
  Future<Result<void>> logout();
}
