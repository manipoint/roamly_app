import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_auth/src/data/models/auth_user_model.dart';
import 'package:roamly_auth/roamly_auth.dart';

void main() {
  const userId = '2db19db1-81b7-467c-b0e1-05bce783522a';

  Map<String, Object?> userJson({String status = 'active'}) {
    return <String, Object?>{
      'id': userId,
      'email': 'traveler@example.com',
      'status': status,
      'created_at': '2026-08-30T10:30:00Z',
    };
  }

  group('AuthUserModel', () {
    test('parses the authentication API response', () {
      final model = AuthUserModel.fromJson(userJson());

      expect(model.id, userId);
      expect(model.email, 'traveler@example.com');
      expect(model.status, 'active');
      expect(model.createdAt, DateTime.utc(2026, 8, 30, 10, 30));
      expect(model.createdAt.isUtc, isTrue);
    });

    for (final testCase in <({String source, AuthUserStatus expected})>[
      (source: 'active', expected: AuthUserStatus.active),
      (source: 'disabled', expected: AuthUserStatus.disabled),
      (source: 'pending', expected: AuthUserStatus.pending),
    ]) {
      test('maps ${testCase.source} to ${testCase.expected}', () {
        final user = AuthUserModel.fromJson(
          userJson(status: testCase.source),
        ).toDomain();

        expect(user.id, userId);
        expect(user.email, 'traveler@example.com');
        expect(user.status, testCase.expected);
        expect(user.createdAt, DateTime.utc(2026, 8, 30, 10, 30));
      });
    }

    test('rejects an unsupported account status', () {
      final model = AuthUserModel.fromJson(userJson(status: 'unexpected'));

      expect(model.toDomain, throwsFormatException);
    });

    test('does not silently accept a missing required field', () {
      final json = userJson()..remove('id');

      expect(() => AuthUserModel.fromJson(json), throwsA(isA<TypeError>()));
    });
  });
}
