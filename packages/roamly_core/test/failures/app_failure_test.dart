import 'package:roamly_core/src/failures/app_failure.dart';
import 'package:test/test.dart';

final class TestFailure extends AppFailure {
  const TestFailure({required super.code, required super.isRetryable});
}

void main() {
  group('AppFailure', () {
    test('preserves its stable machine-readable code', () {
      const failure = TestFailure(
        code: 'network_unavailable',
        isRetryable: true,
      );

      expect(failure.code, 'network_unavailable');
    });

    test('preserves a retryable failure policy', () {
      const failure = TestFailure(code: 'request_timeout', isRetryable: true);

      expect(failure.isRetryable, isTrue);
    });

    test('preserves a non-retryable failure policy', () {
      const failure = TestFailure(
        code: 'invalid_credentials',
        isRetryable: false,
      );

      expect(failure.isRetryable, isFalse);
    });

    test('supports constant failure definitions', () {
      const first = TestFailure(code: 'network_unavailable', isRetryable: true);
      const second = TestFailure(
        code: 'network_unavailable',
        isRetryable: true,
      );

      expect(identical(first, second), isTrue);
    });
  });
}
