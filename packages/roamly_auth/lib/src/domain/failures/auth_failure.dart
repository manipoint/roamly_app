import 'package:roamly_core/roamly_core.dart';

/// Authentication-specific failure categories.
enum AuthFailureKind { sessionStorage }

final class AuthFailure extends AppFailure {
  const AuthFailure({
    required super.code,
    required super.isRetryable,
    required this.kind,
  });

  const AuthFailure.sessionStorage()
    : kind = AuthFailureKind.sessionStorage,
      super(code: 'auth_session_storage_failed', isRetryable: true);

  final AuthFailureKind kind;
}
