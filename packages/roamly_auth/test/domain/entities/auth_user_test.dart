import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_auth/roamly_auth.dart';

void main() {
  final createdAt = DateTime.utc(2026, 8, 30, 10, 30);

  AuthUser createUser({
    String id = '2db19db1-81b7-467c-b0e1-05bce783522a',
    String email = 'traveler@example.com',
    AuthUserStatus status = AuthUserStatus.active,
    DateTime? createdAtOverride,
  }) {
    return AuthUser(
      id: id,
      email: email,
      status: status,
      createdAt: createdAtOverride ?? createdAt,
    );
  }

  group('AuthUser', () {
    test('preserves its domain properties', () {
      final user = createUser();

      expect(user.id, '2db19db1-81b7-467c-b0e1-05bce783522a');
      expect(user.email, 'traveler@example.com');
      expect(user.status, AuthUserStatus.active);
      expect(user.createdAt, createdAt);
    });

    for (final testCase in <({AuthUserStatus status, bool isActive})>[
      (status: AuthUserStatus.active, isActive: true),
      (status: AuthUserStatus.disabled, isActive: false),
      (status: AuthUserStatus.pending, isActive: false),
    ]) {
      test('reports isActive=${testCase.isActive} for ${testCase.status}', () {
        final user = createUser(status: testCase.status);

        expect(user.isActive, testCase.isActive);
      });
    }

    test('uses value equality for identical properties', () {
      final first = createUser();
      final second = createUser(
        createdAtOverride: DateTime.fromMicrosecondsSinceEpoch(
          createdAt.microsecondsSinceEpoch,
          isUtc: true,
        ),
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('distinguishes users with different properties', () {
      final user = createUser();

      expect(user, isNot(createUser(id: 'another-user-id')));
      expect(user, isNot(createUser(email: 'other@example.com')));
      expect(user, isNot(createUser(status: AuthUserStatus.disabled)));
      expect(
        user,
        isNot(
          createUser(
            createdAtOverride: createdAt.add(const Duration(seconds: 1)),
          ),
        ),
      );
    });
  });
}
