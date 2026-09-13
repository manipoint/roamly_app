import 'package:dio/dio.dart';
import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_logging/roamly_logging.dart';
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
  final logger = RoamlyLogger(
    name: 'test.networking',
    sink: const NoopLogSink(),
  );
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
      final executor = DefaultApiRequestExecutor(
        failureMapper: mapper,
        logger: logger,
      );

      final result = await executor.execute<int>(() async => 42);

      expect(result, isA<Success<int>>());
      expect((result as Success<int>).value, 42);
      expect(mapper.calls, 0);
    });

    test('executes the request exactly once', () async {
      final mapper = RecordingFailureMapper(mappedFailure);
      final executor = DefaultApiRequestExecutor(
        failureMapper: mapper,
        logger: logger,
      );
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
      final executor = DefaultApiRequestExecutor(
        failureMapper: mapper,
        logger: logger,
      );

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
      final executor = DefaultApiRequestExecutor(
        failureMapper: mapper,
        logger: logger,
      );

      final result = await executor.execute<String>(() => throw exception);

      expect(result, isA<FailureResult<String>>());
      expect((result as FailureResult<String>).failure, same(mappedFailure));
      expect(mapper.calls, 1);
      expect(mapper.receivedException, same(exception));
    });

    test(
      'preserves invalid cursor through the real mapper without logging the body',
      () async {
        final sink = _RecordingLogSink();
        final executor = DefaultApiRequestExecutor(
          failureMapper: const DefaultDioFailureMapper(),
          logger: RoamlyLogger(name: 'network', sink: sink),
        );
        final options = RequestOptions(path: '/destinations');
        var calls = 0;
        final result = await executor.execute<void>(() async {
          calls++;
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<Object?>(
              requestOptions: options,
              statusCode: 422,
              data: {
                'error': {
                  'code': 'invalid_cursor',
                  'message': 'private-response-detail',
                },
              },
            ),
          );
        });
        final failure =
            (result as FailureResult<void>).failure as NetworkFailure;
        expect(failure.backendCode, 'invalid_cursor');
        expect(failure.code, 'request_validation_failed');
        expect(failure.statusCode, 422);
        expect(failure.isRetryable, isFalse);
        expect(calls, 1);
        expect(
          sink.records.single.fields.toString(),
          isNot(contains('private-response-detail')),
        );
        expect(sink.records.single.message, 'API request failed');
      },
    );

    test('does not swallow an asynchronous unexpected exception', () async {
      final mapper = RecordingFailureMapper(mappedFailure);
      final executor = DefaultApiRequestExecutor(
        failureMapper: mapper,
        logger: logger,
      );
      final unexpected = StateError('invalid response model');

      await expectLater(
        executor.execute<String>(() => Future<String>.error(unexpected)),
        throwsA(same(unexpected)),
      );
      expect(mapper.calls, 0);
    });

    test('does not swallow a synchronous unexpected exception', () async {
      final mapper = RecordingFailureMapper(mappedFailure);
      final executor = DefaultApiRequestExecutor(
        failureMapper: mapper,
        logger: logger,
      );
      final unexpected = FormatException('invalid response payload');

      await expectLater(
        executor.execute<String>(() => throw unexpected),
        throwsA(same(unexpected)),
      );
      expect(mapper.calls, 0);
    });

    test('logs mapped request failures without request data', () async {
      final sink = _RecordingLogSink();
      final executor = DefaultApiRequestExecutor(
        failureMapper: RecordingFailureMapper(mappedFailure),
        logger: RoamlyLogger(name: 'network', sink: sink),
      );
      final exception = DioException(
        requestOptions: RequestOptions(
          path: '/trips?access_token=secret',
          method: 'GET',
          data: const {'password': 'must-not-be-logged'},
        ),
        response: Response<void>(
          requestOptions: RequestOptions(path: '/trips'),
          statusCode: 504,
        ),
        type: DioExceptionType.badResponse,
      );

      await executor.execute<void>(() => throw exception);

      final record = sink.records.single;
      expect(record.level, LogLevel.warning);
      expect(record.message, 'API request failed');
      expect(record.fields['request_uri'], '/trips');
      expect(record.fields['status_code'], 504);
      expect(record.fields['failure_code'], 'network_timeout');
      expect(record.fields.toString(), isNot(contains('must-not-be-logged')));
      expect(record.fields.toString(), isNot(contains('secret')));
    });
  });
}

final class _RecordingLogSink implements LogSink {
  final List<LogRecord> records = [];

  @override
  void write(LogRecord record) {
    records.add(record);
  }
}
