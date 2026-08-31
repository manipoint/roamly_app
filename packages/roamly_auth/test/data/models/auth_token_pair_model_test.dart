import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_auth/src/data/models/auth_token_pair_model.dart';

void main() {
  Map<String, Object?> tokenJson() {
    return <String, Object?>{
      'access_token': 'access-secret',
      'refresh_token': 'refresh-secret',
      'token_type': 'bearer',
      'access_token_expires_at': '2026-08-30T10:45:00Z',
      'refresh_token_expires_at': '2026-09-29T10:30:00Z',
    };
  }

  group('AuthTokenPairModel', () {
    test('parses the authentication token response', () {
      final model = AuthTokenPairModel.fromJson(tokenJson());

      expect(model.accessToken, 'access-secret');
      expect(model.refreshToken, 'refresh-secret');
      expect(model.tokenType, 'bearer');
      expect(model.accessTokenExpiresAt, DateTime.utc(2026, 8, 30, 10, 45));
      expect(model.refreshTokenExpiresAt, DateTime.utc(2026, 9, 29, 10, 30));
      expect(model.accessTokenExpiresAt.isUtc, isTrue);
      expect(model.refreshTokenExpiresAt.isUtc, isTrue);
    });

    test('normalizes offset timestamps to UTC', () {
      final json = tokenJson()
        ..['access_token_expires_at'] = '2026-08-30T15:45:00+05:00';

      final model = AuthTokenPairModel.fromJson(json);

      expect(model.accessTokenExpiresAt, DateTime.utc(2026, 8, 30, 10, 45));
      expect(model.accessTokenExpiresAt.isUtc, isTrue);
    });

    test('does not silently accept a missing access token', () {
      final json = tokenJson()..remove('access_token');

      expect(
        () => AuthTokenPairModel.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });

    test('rejects an invalid expiry timestamp', () {
      final json = tokenJson()..['access_token_expires_at'] = 'not-a-date';

      expect(() => AuthTokenPairModel.fromJson(json), throwsFormatException);
    });

    test('does not expose credentials through its default string value', () {
      final model = AuthTokenPairModel.fromJson(tokenJson());

      expect(model.toString(), isNot(contains('access-secret')));
      expect(model.toString(), isNot(contains('refresh-secret')));
    });
  });
}
