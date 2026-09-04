import 'package:dio/dio.dart';
import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_logging/roamly_logging.dart';

import '../failures/dio_failure_mapper.dart';

/// Executes API operations and converts expected Dio errors into safe results.
abstract interface class ApiRequestExecutor {
  Future<Result<T>> execute<T>(Future<T> Function() request);
}

/// Default API request execution boundary.

final class DefaultApiRequestExecutor implements ApiRequestExecutor {
  const DefaultApiRequestExecutor({
    required DioFailureMapper failureMapper,
    required RoamlyLogger logger,
  }) : _failureMapper = failureMapper,
       _logger = logger;

  final DioFailureMapper _failureMapper;
  final RoamlyLogger _logger;

  @override
  Future<Result<T>> execute<T>(Future<T> Function() request) async {
    try {
      final value = await request();
      return Success<T>(value);
    } on DioException catch (exception) {
      final failure = _failureMapper.map(exception);
      _logger.warning(
        'API request failed',
        fields: {
          'method': exception.requestOptions.method,
          'request_uri': exception.requestOptions.uri,
          'status_code': exception.response?.statusCode,
          'dio_exception_type': exception.type.name,
          'failure_code': failure.code,
          'is_retryable': failure.isRetryable,
        },
        stackTrace: exception.stackTrace,
      );
      return FailureResult<T>(failure);
    }
  }
}
