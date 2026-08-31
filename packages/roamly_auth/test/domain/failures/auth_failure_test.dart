import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_auth/roamly_auth.dart';
import 'package:roamly_core/roamly_core.dart';

void main() {
  group('AuthFailure', () {
    test('sessionStorage exposes a stable safe failure contract', () {
      const failure = AuthFailure.sessionStorage();

      expect(failure, isA<AppFailure>());
      expect(failure.kind, AuthFailureKind.sessionStorage);
      expect(failure.code, 'auth_session_storage_failed');
      expect(failure.isRetryable, isTrue);
    });

    test('preserves explicitly supplied failure properties', () {
      const failure = AuthFailure(
        code: 'auth_example_failure',
        isRetryable: false,
        kind: AuthFailureKind.sessionStorage,
      );

      expect(failure.code, 'auth_example_failure');
      expect(failure.isRetryable, isFalse);
      expect(failure.kind, AuthFailureKind.sessionStorage);
    });
  });
}
