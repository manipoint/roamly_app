import 'package:dio/dio.dart';
import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_networking/roamly_networking.dart';
import 'package:test/test.dart';

final class RecordingFailureMapper implements DioFailureMapper {
  RecordingFailureMapper(this.failure);

  final NetworkFailure failure;
  int calls = 0;
  DioException? receivedException;

  @override
  NetworkFailure map(DioException exception) {
    calls++;
    receivedException = exception;
    return failure;
  }
}

void main() {
  const mappedFailure = NetworkFailure(
    code: 'network_timeout',
    isRetryable: true,
    kind: NetworkFailureKind.timeout,
  );

  DioException dioException() {
    return DioException(
      requestOptions: RequestOptions(path: '/trips'),
      type: DioExceptionType.receiveTimeout,
    );
  }

  group('DefaultApiRequestExecutor', () {
    test('returns a typed success value', () async {
      final mapper = RecordingFailureMapper(mappedFailure);
      final executor = DefaultApiRequestExecutor(failureMapper: mapper);

      final result = await executor.execute<int>(() async => 42);

      expect(result, isA<Success<int>>());
      expect((result as Success<int>).value, 42);
      expect(mapper.calls, 0);
    });

    test('executes the request exactly once', () async {
      final mapper = RecordingFailureMapper(mappedFailure);
      final executor = DefaultApiRequestExecutor(failureMapper: mapper);
      var requestCalls = 0;

      final result = await executor.execute<String>(() async {
        requestCalls++;
        return 'completed';
      });

      expect(requestCalls, 1);
      expect(result, isA<Success<String>>());
    });

    test('maps an asynchronously delivered DioException', () async {
      final exception = dioException();
      final mapper = RecordingFailureMapper(mappedFailure);
      final executor = DefaultApiRequestExecutor(failureMapper: mapper);

      final result = await executor.execute<String>(
        () => Future<String>.error(exception),
      );

      expect(result, isA<FailureResult<String>>());
      expect((result as FailureResult<String>).failure, same(mappedFailure));
      expect(mapper.calls, 1);
      expect(mapper.receivedException, same(exception));
    });

    test('maps a synchronously thrown DioException', () async {
      final exception = dioException();
      final mapper = RecordingFailureMapper(mappedFailure);
      final executor = DefaultApiRequestExecutor(failureMapper: mapper);

      final result = await executor.execute<String>(() => throw exception);

      expect(result, isA<FailureResult<String>>());
      expect((result as FailureResult<String>).failure, same(mappedFailure));
      expect(mapper.calls, 1);
      expect(mapper.receivedException, same(exception));
    });

    test('does not swallow an asynchronous unexpected exception', () async {
      final mapper = RecordingFailureMapper(mappedFailure);
      final executor = DefaultApiRequestExecutor(failureMapper: mapper);
      final unexpected = StateError('invalid response model');

      await expectLater(
        executor.execute<String>(() => Future<String>.error(unexpected)),
        throwsA(same(unexpected)),
      );
      expect(mapper.calls, 0);
    });

    test('does not swallow a synchronous unexpected exception', () async {
      final mapper = RecordingFailureMapper(mappedFailure);
      final executor = DefaultApiRequestExecutor(failureMapper: mapper);
      final unexpected = FormatException('invalid response payload');

      await expectLater(
        executor.execute<String>(() => throw unexpected),
        throwsA(same(unexpected)),
      );
      expect(mapper.calls, 0);
    });
  });
}
