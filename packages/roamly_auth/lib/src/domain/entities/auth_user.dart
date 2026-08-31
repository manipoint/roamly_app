/// Supported Roamly account lifecycle states.
enum AuthUserStatus { active, disabled, pending }

/// Authenticated user identity used by application features.

final class AuthUser {
  final String id;
  final String email;
  final AuthUserStatus status;
  final DateTime createdAt;

  const AuthUser({
    required this.id,
    required this.email,
    required this.status,
    required this.createdAt,
  });

  bool get isActive => status == AuthUserStatus.active;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthUser &&
            other.id == id &&
            other.email == email &&
            other.status == status &&
            other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, email, status, createdAt);
}
