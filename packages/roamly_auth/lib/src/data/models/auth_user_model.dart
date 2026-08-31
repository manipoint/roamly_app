import '../../domain/entities/auth_user.dart';

/// Transport representation of a user returned by the authentication API.

final class AuthUserModel {
  final String id;
  final String email;
  final String status;
  final DateTime createdAt;

  const AuthUserModel({
    required this.id,
    required this.email,
    required this.status,
    required this.createdAt,
  });

  factory AuthUserModel.fromJson(Map<String, Object?> json) {
    return AuthUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    );
  }

  AuthUser toDomain() {
    return AuthUser(
      id: id,
      email: email,
      status: _parsedStatus(status),
      createdAt: createdAt,
    );
  }

  static AuthUserStatus _parsedStatus(String status) {
    return switch (status) {
      'active' => AuthUserStatus.active,
      'disabled' => AuthUserStatus.disabled,
      'pending' => AuthUserStatus.pending,
      _ => throw FormatException("Unsupported authentication user status"),
    };
  }
}
