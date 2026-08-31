import 'package:roamly_core/roamly_core.dart';
import 'package:test/test.dart';

final class TestFailure extends AppFailure {
  const TestFailure({required super.code, required super.isRetryable});
}

void main() {
  group('Success', () {
    test('reports only the success state', () {
      const result = Success<int>(42);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.value, 42);
    });

    test('fold invokes only the success callback', () {
      const result = Success<int>(42);
      var successCalls = 0;
      var failureCalls = 0;

      final output = result.fold<String>(
        onSuccess: (value) {
          successCalls++;
          return 'value:$value';
        },
        onFailure: (failure) {
          failureCalls++;
          return 'failure:${failure.code}';
        },
      );

      expect(output, 'value:42');
      expect(successCalls, 1);
      expect(failureCalls, 0);
    });

    test('map transforms the value and its generic type', () {
      const result = Success<int>(42);

      final mapped = result.map((value) => 'value:$value');

      expect(mapped, isA<Success<String>>());
      expect((mapped as Success<String>).value, 'value:42');
    });

    test('supports constant construction', () {
      const first = Success<int>(42);
      const second = Success<int>(42);

      expect(identical(first, second), isTrue);
    });
  });

  group('FailureResult', () {
    const failure = TestFailure(code: 'network_unavailable', isRetryable: true);

    test('reports only the failure state', () {
      const result = FailureResult<int>(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.failure, same(failure));
    });

    test('fold invokes only the failure callback', () {
      const result = FailureResult<int>(failure);
      var successCalls = 0;
      var failureCalls = 0;

      final output = result.fold<String>(
        onSuccess: (value) {
          successCalls++;
          return 'value:$value';
        },
        onFailure: (receivedFailure) {
          failureCalls++;
          return 'failure:${receivedFailure.code}';
        },
      );

      expect(output, 'failure:network_unavailable');
      expect(successCalls, 0);
      expect(failureCalls, 1);
    });

    test('map preserves the failure without invoking the transform', () {
      const result = FailureResult<int>(failure);
      var transformCalls = 0;

      final mapped = result.map<String>((value) {
        transformCalls++;
        return 'value:$value';
      });

      expect(transformCalls, 0);
      expect(mapped, isA<FailureResult<String>>());
      expect((mapped as FailureResult<String>).failure, same(failure));
    });

    test('supports constant construction', () {
      const first = FailureResult<int>(failure);
      const second = FailureResult<int>(failure);

      expect(identical(first, second), isTrue);
    });
  });

  test('supports non-primitive generic values', () {
    const result = Success<(int, String)>((7, 'Lahore'));

    final output = result.fold<String>(
      onSuccess: (value) => '${value.$1}:${value.$2}',
      onFailure: (failure) => failure.code,
    );

    expect(output, '7:Lahore');
  });
}
