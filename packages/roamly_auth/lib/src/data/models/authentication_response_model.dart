import 'auth_token_pair_model.dart';

import 'auth_user_model.dart';

/// Complete authentication payload returned after login or registration.
final class AuthenticationResponseModel {
  final AuthUserModel user;
  final AuthTokenPairModel tokens;

  const AuthenticationResponseModel({required this.user, required this.tokens});

  factory AuthenticationResponseModel.fromJson(Map<String, Object?> json) {
    return AuthenticationResponseModel(
      user: AuthUserModel.fromJson(
        _readJsonObject(json['user'], fieldName: 'user'),
      ),
      tokens: AuthTokenPairModel.fromJson(
        _readJsonObject(json['tokens'], fieldName: 'tokens'),
      ),
    );
  }

  static Map<String, Object?> _readJsonObject(
    Object? value, {
    required String fieldName,
  }) {
    if (value is Map<String, Object?>) {
      return value;
    }
    throw FormatException('$fieldName must be a JSON object');
  }
}
