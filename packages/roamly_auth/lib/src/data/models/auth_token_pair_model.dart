/// Authentication credentials returned by login, registration, or refresh.
final class AuthTokenPairModel {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final DateTime accessTokenExpiresAt;
  final DateTime refreshTokenExpiresAt;

  const AuthTokenPairModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.accessTokenExpiresAt,
    required this.refreshTokenExpiresAt,
  });

  factory AuthTokenPairModel.fromJson(Map<String, Object?> json) {
    return AuthTokenPairModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String,

      accessTokenExpiresAt: DateTime.parse(
        json['access_token_expires_at'] as String,
      ).toUtc(),
      refreshTokenExpiresAt: DateTime.parse(
        json['refresh_token_expires_at'] as String,
      ).toUtc(),
    );
  }
}
