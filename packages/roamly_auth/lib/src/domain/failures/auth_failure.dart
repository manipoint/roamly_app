import 'package:roamly_core/roamly_core.dart';

/// Authentication-specific failure categories.
enum AuthFailureKind { sessionStorage ,  deviceIdentity ,}

/// A safe authentication-specific application failure.
final class AuthFailure extends AppFailure {
  const AuthFailure({
    required super.code,
    required super.isRetryable,
    required this.kind,
  });

  const AuthFailure.sessionStorage()
    : kind = AuthFailureKind.sessionStorage,
      super(code: 'auth_session_storage_failed', isRetryable: true);

const AuthFailure.deviceIdentity()
    : kind = AuthFailureKind.deviceIdentity,
      super(code: 'auth_device_identity_failed', isRetryable: true);

  /// Category used by application logic.
  final AuthFailureKind kind;
}
