import 'package:dio/dio.dart';

import 'network_failure.dart';

abstract interface class DioFailureMapper {
  NetworkFailure map(DioException exception);
}

final class DefaultDioFailureMapper implements DioFailureMapper {
  const DefaultDioFailureMapper();

  static final RegExp _backendCodePattern = RegExp(r'^[a-z][a-z0-9_]{0,63}$');

  @override
  NetworkFailure map(DioException exception) {
    return switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.transformTimeout => const NetworkFailure(
        code: 'network_timeout',
        isRetryable: true,
        kind: NetworkFailureKind.timeout,
      ),
      DioExceptionType.connectionError => const NetworkFailure(
        code: 'network_connection_failed',
        isRetryable: true,
        kind: NetworkFailureKind.connection,
      ),
      DioExceptionType.cancel => const NetworkFailure(
        code: 'request_cancelled',
        isRetryable: false,
        kind: NetworkFailureKind.cancelled,
      ),
      DioExceptionType.badResponse => _fromResponse(exception.response),
      DioExceptionType.badCertificate ||
      DioExceptionType.unknown => const NetworkFailure(
        code: 'network_unknown',
        isRetryable: false,
        kind: NetworkFailureKind.unknown,
      ),
    };
  }

  static NetworkFailure _fromResponse(Response<dynamic>? response) {
    final statusCode = response?.statusCode;
    final backendCode = _readBackendCode(response?.data);

    final (code, kind, retryable) = switch (statusCode) {
      400 || 422 => (
        'request_validation_failed',
        NetworkFailureKind.validation,
        false,
      ),
      401 => ('unauthorized', NetworkFailureKind.unauthorized, false),
      403 => ('forbidden', NetworkFailureKind.forbidden, false),
      404 => ('resource_not_found', NetworkFailureKind.notFound, false),
      408 => ('network_timeout', NetworkFailureKind.timeout, true),
      409 => ('resource_conflict', NetworkFailureKind.conflict, false),
      429 => ('rate_limited', NetworkFailureKind.rateLimited, true),
      int status when status >= 500 && status <= 599 => (
        'server_error',
        NetworkFailureKind.server,
        true,
      ),
      _ => ('network_unknown', NetworkFailureKind.unknown, false),
    };

    return NetworkFailure(
      code: code,
      kind: kind,
      isRetryable: retryable,
      statusCode: statusCode,
      backendCode: backendCode,
    );
  }

  static String? _readBackendCode(Object? data) {
    if (data is! Map) return null;

    final error = data['error'];
    if (error is! Map) return null;

    final code = error['code'];
    if (code is! String ||
        code.isEmpty ||
        code.length > 64 ||
        !_backendCodePattern.hasMatch(code)) {
      return null;
    }

    return code;
  }
}
