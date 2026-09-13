import 'package:dio/dio.dart';
import 'package:roamly_networking/roamly_networking.dart';
import 'package:test/test.dart';

void main() {
  const mapper = DefaultDioFailureMapper();

  DioException exception({
    required DioExceptionType type,
    int? statusCode,
    Object? responseData,
  }) {
    final requestOptions = RequestOptions(path: '/resource');

    return DioException(
      requestOptions: requestOptions,
      type: type,
      response: type == DioExceptionType.badResponse
          ? Response<Object?>(
              requestOptions: requestOptions,
              statusCode: statusCode,
              data: responseData,
            )
          : null,
    );
  }

  void expectFailure(
    NetworkFailure failure, {
    required NetworkFailureKind kind,
    required String code,
    required bool isRetryable,
    int? statusCode,
    String? backendCode,
  }) {
    expect(failure.backendCode, backendCode);
    expect(failure.kind, kind);
    expect(failure.code, code);
    expect(failure.isRetryable, isRetryable);
    expect(failure.statusCode, statusCode);
  }

  group('DefaultDioFailureMapper', () {
    for (final type in <DioExceptionType>[
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.transformTimeout,
    ]) {
      test('maps $type to a retryable timeout failure', () {
        final failure = mapper.map(exception(type: type));

        expectFailure(
          failure,
          kind: NetworkFailureKind.timeout,
          code: 'network_timeout',
          isRetryable: true,
        );
      });
    }

    test('maps a connection error to a retryable connection failure', () {
      final failure = mapper.map(
        exception(type: DioExceptionType.connectionError),
      );

      expectFailure(
        failure,
        kind: NetworkFailureKind.connection,
        code: 'network_connection_failed',
        isRetryable: true,
      );
    });

    test('maps cancellation to a non-retryable cancelled failure', () {
      final failure = mapper.map(exception(type: DioExceptionType.cancel));

      expectFailure(
        failure,
        kind: NetworkFailureKind.cancelled,
        code: 'request_cancelled',
        isRetryable: false,
      );
    });

    for (final type in <DioExceptionType>[
      DioExceptionType.badCertificate,
      DioExceptionType.unknown,
    ]) {
      test('maps $type to a non-retryable unknown failure', () {
        final failure = mapper.map(exception(type: type));

        expectFailure(
          failure,
          kind: NetworkFailureKind.unknown,
          code: 'network_unknown',
          isRetryable: false,
        );
      });
    }

    final statusCases =
        <
          ({
            int statusCode,
            NetworkFailureKind kind,
            String code,
            bool isRetryable,
          })
        >[
          (
            statusCode: 400,
            kind: NetworkFailureKind.validation,
            code: 'request_validation_failed',
            isRetryable: false,
          ),
          (
            statusCode: 401,
            kind: NetworkFailureKind.unauthorized,
            code: 'unauthorized',
            isRetryable: false,
          ),
          (
            statusCode: 403,
            kind: NetworkFailureKind.forbidden,
            code: 'forbidden',
            isRetryable: false,
          ),
          (
            statusCode: 404,
            kind: NetworkFailureKind.notFound,
            code: 'resource_not_found',
            isRetryable: false,
          ),
          (
            statusCode: 408,
            kind: NetworkFailureKind.timeout,
            code: 'network_timeout',
            isRetryable: true,
          ),
          (
            statusCode: 409,
            kind: NetworkFailureKind.conflict,
            code: 'resource_conflict',
            isRetryable: false,
          ),
          (
            statusCode: 422,
            kind: NetworkFailureKind.validation,
            code: 'request_validation_failed',
            isRetryable: false,
          ),
          (
            statusCode: 429,
            kind: NetworkFailureKind.rateLimited,
            code: 'rate_limited',
            isRetryable: true,
          ),
          (
            statusCode: 500,
            kind: NetworkFailureKind.server,
            code: 'server_error',
            isRetryable: true,
          ),
          (
            statusCode: 599,
            kind: NetworkFailureKind.server,
            code: 'server_error',
            isRetryable: true,
          ),
        ];

    for (final testCase in statusCases) {
      test('maps HTTP ${testCase.statusCode} to ${testCase.kind}', () {
        final failure = mapper.map(
          exception(
            type: DioExceptionType.badResponse,
            statusCode: testCase.statusCode,
          ),
        );

        expectFailure(
          failure,
          kind: testCase.kind,
          code: testCase.code,
          isRetryable: testCase.isRetryable,
          statusCode: testCase.statusCode,
        );
      });
    }

    test('preserves a missing response status as null', () {
      final failure = mapper.map(exception(type: DioExceptionType.badResponse));

      expectFailure(
        failure,
        kind: NetworkFailureKind.unknown,
        code: 'network_unknown',
        isRetryable: false,
      );
    });

    test('maps an unrecognized HTTP status to unknown', () {
      final failure = mapper.map(
        exception(type: DioExceptionType.badResponse, statusCode: 418),
      );

      expectFailure(
        failure,
        kind: NetworkFailureKind.unknown,
        code: 'network_unknown',
        isRetryable: false,
        statusCode: 418,
      );
    });

    test(
      'preserves backend classification without changing transport policy',
      () {
        for (final testCase in statusCases) {
          final failure = mapper.map(
            exception(
              type: DioExceptionType.badResponse,
              statusCode: testCase.statusCode,
              responseData: {
                'error': {
                  'code': 'invalid_cursor',
                  'message': 'private detail',
                },
              },
            ),
          );
          expectFailure(
            failure,
            kind: testCase.kind,
            code: testCase.code,
            isRetryable: testCase.isRetryable,
            statusCode: testCase.statusCode,
            backendCode: 'invalid_cursor',
          );
        }
      },
    );

    test('accepts bounded backend codes without altering them', () {
      for (final code in ['a', 'invalid_cursor', 'error_42', 'a' * 64]) {
        final failure = mapper.map(
          exception(
            type: DioExceptionType.badResponse,
            statusCode: 422,
            responseData: {
              'error': {'code': code},
            },
          ),
        );
        expect(failure.backendCode, code);
      }
    });

    test('ignores malformed error envelopes and invalid backend codes', () {
      final bodies = <Object?>[
        null,
        'not JSON',
        [],
        {},
        {'code': 'invalid_cursor'},
        {'error': null},
        {'error': []},
        {'error': 'invalid_cursor'},
        {'error': {}},
        for (final code in <Object?>[
          null,
          42,
          [],
          {},
          '',
          'a' * 65,
          'INVALID_CURSOR',
          'invalid-cursor',
          ' invalid_cursor',
          'invalid_cursor ',
          'invalid_cursor\n',
          'invalid\ncursor',
          '1invalid',
          '_invalid',
          'érror',
        ])
          {
            'error': {'code': code},
          },
      ];
      for (final body in bodies) {
        final failure = mapper.map(
          exception(
            type: DioExceptionType.badResponse,
            statusCode: 422,
            responseData: body,
          ),
        );
        expectFailure(
          failure,
          kind: NetworkFailureKind.validation,
          code: 'request_validation_failed',
          isRetryable: false,
          statusCode: 422,
        );
      }
    });

    test('handles an absent response object', () {
      final failure = mapper.map(
        DioException(
          requestOptions: RequestOptions(path: '/resource'),
          type: DioExceptionType.badResponse,
        ),
      );
      expectFailure(
        failure,
        kind: NetworkFailureKind.unknown,
        code: 'network_unknown',
        isRetryable: false,
      );
    });

    test('does not expose response data through the failure', () {
      final failure = mapper.map(
        exception(
          type: DioExceptionType.badResponse,
          statusCode: 500,
          responseData: <String, Object?>{
            'detail': 'internal database error',
            'token': 'secret-token',
          },
        ),
      );

      expect(failure.code, 'server_error');
      expect(failure.toString(), isNot(contains('internal database error')));
      expect(failure.toString(), isNot(contains('secret-token')));
    });
  });
}
