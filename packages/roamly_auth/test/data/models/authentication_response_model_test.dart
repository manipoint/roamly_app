import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_auth/src/data/models/authentication_response_model.dart';
import 'package:roamly_auth/roamly_auth.dart';

void main() {
  Map<String, Object?> authenticationJson() {
    return <String, Object?>{
      'user': <String, Object?>{
        'id': '2db19db1-81b7-467c-b0e1-05bce783522a',
        'email': 'traveler@example.com',
        'status': 'active',
        'created_at': '2026-08-30T10:30:00Z',
      },
      'tokens': <String, Object?>{
        'access_token': 'access-secret',
        'refresh_token': 'refresh-secret',
        'token_type': 'bearer',
        'access_token_expires_at': '2026-08-30T10:45:00Z',
        'refresh_token_expires_at': '2026-09-29T10:30:00Z',
      },
    };
  }

  group('AuthenticationResponseModel', () {
    test('parses nested user and token-pair objects', () {
      final response = AuthenticationResponseModel.fromJson(
        authenticationJson(),
      );

      final user = response.user.toDomain();
      expect(user.email, 'traveler@example.com');
      expect(user.status, AuthUserStatus.active);
      expect(response.tokens.accessToken, 'access-secret');
      expect(response.tokens.refreshToken, 'refresh-secret');
      expect(response.tokens.tokenType, 'bearer');
    });

    for (final fieldName in <String>['user', 'tokens']) {
      test('rejects a missing $fieldName object', () {
        final json = authenticationJson()..remove(fieldName);

        expect(
          () => AuthenticationResponseModel.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              '$fieldName must be a JSON object',
            ),
          ),
        );
      });

      test('rejects a non-object $fieldName value', () {
        final json = authenticationJson()..[fieldName] = 'invalid';

        expect(
          () => AuthenticationResponseModel.fromJson(json),
          throwsA(isA<FormatException>()),
        );
      });
    }

    test('delegates validation of nested token fields', () {
      final json = authenticationJson();
      final tokens = json['tokens'] as Map<String, Object?>;
      tokens.remove('access_token');

      expect(
        () => AuthenticationResponseModel.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });

    test('does not expose nested credentials through its string value', () {
      final response = AuthenticationResponseModel.fromJson(
        authenticationJson(),
      );

      expect(response.toString(), isNot(contains('access-secret')));
      expect(response.toString(), isNot(contains('refresh-secret')));
    });
  });
}
