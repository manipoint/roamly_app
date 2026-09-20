import 'package:dio/dio.dart';
import 'package:roamly_logging/roamly_logging.dart';

/// Logs bounded and sanitized HTTP diagnostics.
///
/// Attach this interceptor only in debug builds. It never logs request headers,
/// raw Dio exceptions, binary data, or complete multipart files.
final class ApiDebugLoggingInterceptor extends Interceptor {
  ApiDebugLoggingInterceptor({required RoamlyLogger logger}) : _logger = logger;

  static const String _requestIdKey = 'roamly.networking.debug.request_id';

  static const String _stopwatchKey = 'roamly.networking.debug.stopwatch';

  static const int _maximumStringLength = 1000;
  static const int _maximumCollectionItems = 25;
  static const int _maximumDepth = 6;

  final RoamlyLogger _logger;

  int _sequence = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requestId = _nextRequestId();
    final stopwatch = Stopwatch()..start();

    options.extra[_requestIdKey] = requestId;
    options.extra[_stopwatchKey] = stopwatch;

    _logger.debug(
      'HTTP request',
      fields: {
        'request_id': requestId,
        'method': options.method,
        'endpoint': _safeEndpoint(options),
        'query_parameters': _preview(options.queryParameters),
        'request_body': _preview(options.data),
        'response_type': options.responseType.name,
      },
    );

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;

    _logger.debug(
      'HTTP response',
      fields: {
        'request_id': _requestId(options),
        'method': options.method,
        'endpoint': _safeEndpoint(options),
        'status_code': response.statusCode,
        'duration_ms': _finishStopwatch(options),
        'server_request_id': response.headers.value('x-request-id'),
        'response_body': _preview(response.data),
      },
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final response = err.response;

    // Do not pass the DioException or its message to the logger. They may
    // contain headers, query parameters, request bodies, or provider details.
    _logger.debug(
      'HTTP failure response',
      fields: {
        'request_id': _requestId(options),
        'method': options.method,
        'endpoint': _safeEndpoint(options),
        'status_code': response?.statusCode,
        'duration_ms': _finishStopwatch(options),
        'dio_exception_type': err.type.name,
        'server_request_id': response?.headers.value('x-request-id'),
        'response_body': _preview(response?.data),
      },
    );

    handler.next(err);
  }

  String _nextRequestId() {
    _sequence++;
    return 'http-${DateTime.now().microsecondsSinceEpoch}-$_sequence';
  }

  static String? _requestId(RequestOptions options) {
    final value = options.extra[_requestIdKey];
    return value is String ? value : null;
  }

  static int? _finishStopwatch(RequestOptions options) {
    final value = options.extra.remove(_stopwatchKey);

    if (value is! Stopwatch) {
      return null;
    }

    value.stop();
    return value.elapsedMilliseconds;
  }

  static Uri _safeEndpoint(RequestOptions options) {
    return options.uri.replace(userInfo: '', query: '', fragment: '');
  }

  static Object? _preview(Object? value, {int depth = 0}) {
    if (value == null || value is bool || value is num) {
      return value;
    }

    if (depth >= _maximumDepth) {
      return '[MAX_DEPTH_REACHED]';
    }

    if (value is String) {
      if (value.length <= _maximumStringLength) {
        return value;
      }

      return '${value.substring(0, _maximumStringLength)}'
          '[TRUNCATED:${value.length - _maximumStringLength}]';
    }

    if (value is FormData) {
      return {
        'fields': {
          for (final field in value.fields)
            field.key: _preview(field.value, depth: depth + 1),
        },
        'file_fields': [
          for (final file in value.files.take(_maximumCollectionItems))
            file.key,
        ],
        'file_count': value.files.length,
      };
    }

    if (value is MultipartFile) {
      return {'type': 'multipart_file', 'length': value.length};
    }

    if (value is Map) {
      final entries = value.entries
          .take(_maximumCollectionItems)
          .toList(growable: false);

      return {
        for (final entry in entries)
          entry.key.toString(): _preview(entry.value, depth: depth + 1),
        if (value.length > _maximumCollectionItems)
          '_truncated_fields': value.length - _maximumCollectionItems,
      };
    }

    if (value is Iterable) {
      final items = value
          .take(_maximumCollectionItems)
          .map((item) => _preview(item, depth: depth + 1))
          .toList(growable: false);

      return {
        'items': items,
        if (value.length > _maximumCollectionItems)
          '_truncated_items': value.length - _maximumCollectionItems,
      };
    }

    return '[${value.runtimeType}]';
  }
}
