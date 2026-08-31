import 'package:dio/dio.dart';
import 'network_failure.dart';

abstract interface class DioFailureMapper {
  NetworkFailure map(DioException exception);
}

/// Default mapping policy for HTTP transport failures.

final class DefaultDioFailureMapper implements DioFailureMapper {
  const DefaultDioFailureMapper();
  @override
  NetworkFailure map(DioException exception) {
    return switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.transformTimeout => _timeout(),
      DioExceptionType.connectionError => _connection(),
      DioExceptionType.cancel => const NetworkFailure(
        code: 'request_cancelled',
        isRetryable: false,
        kind: NetworkFailureKind.cancelled,
      ),
      DioExceptionType.badResponse => _fromStatusCode(
        exception.response?.statusCode,
      ),
      DioExceptionType.badCertificate ||
      DioExceptionType.unknown => const NetworkFailure(
        code: "network_unknown",
        isRetryable: false,
        kind: NetworkFailureKind.unknown,
      ),
    };
  }

  static NetworkFailure _timeout() {
    return const NetworkFailure(
      code: 'network_timeout',
      isRetryable: true,
      kind: NetworkFailureKind.timeout,
    );
  }

  static NetworkFailure _connection() {
    return const NetworkFailure(
      code: 'network_connection_failed',
      isRetryable: true,
      kind: NetworkFailureKind.connection,
    );
  }

  static NetworkFailure _fromStatusCode(int? statusCode) {
    return switch (statusCode) {
      400 || 422 => NetworkFailure(
        code: 'request_validation_failed',
        isRetryable: false,
        kind: NetworkFailureKind.validation,
        statusCode: statusCode,
      ),
      401 => NetworkFailure(
        code: 'unauthorized',
        isRetryable: false,
        kind: NetworkFailureKind.unauthorized,
        statusCode: statusCode,
      ),
      403 => NetworkFailure(
        code: "forbidden",
        isRetryable: false,
        kind: NetworkFailureKind.forbidden,
        statusCode: statusCode,
      ),
      404 => NetworkFailure(
        code: "resource_not_found",
        isRetryable: false,
        kind: NetworkFailureKind.notFound,
        statusCode: statusCode,
      ),
      408 => NetworkFailure(
        code: 'network_timeout',
        isRetryable: true,
        kind: NetworkFailureKind.timeout,
        statusCode: statusCode,
      ),
      409 => NetworkFailure(
        code: "resource_conflict",
        isRetryable: false,
        kind: NetworkFailureKind.conflict,
        statusCode: statusCode,
      ),
      429 => NetworkFailure(
        code: "rate_limited",
        isRetryable: true,
        kind: NetworkFailureKind.rateLimited,
        statusCode: statusCode,
      ),
      int code when code >= 500 && code <= 599 => NetworkFailure(
        code: 'server_error',
        isRetryable: true,
        kind: NetworkFailureKind.server,
        statusCode: statusCode,
      ),
      _ => NetworkFailure(
        code: "network_unknown",
        isRetryable: false,
        kind: NetworkFailureKind.unknown,
        statusCode: statusCode,
      ),
    };
  }
}
