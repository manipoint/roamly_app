import 'package:dio/dio.dart';

import 'access_token_provider.dart';

/// Adds the current bearer access token to outgoing requests.
final class BearerTokenInterceptor extends Interceptor {
  BearerTokenInterceptor(AccessTokenProvider accessTokenProvider)
    : _accessTokenProvider = accessTokenProvider;

  static const _authorizationHeader = 'Authorization';

  final AccessTokenProvider _accessTokenProvider;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_hasAuthorizationHeader(options.headers)) {
      handler.next(options);
      return;
    }

    try {
      final token = (await _accessTokenProvider.readAccessToken())?.trim();

      if (token != null && token.isNotEmpty) {
        options.headers[_authorizationHeader] = 'Bearer $token';
      }

      handler.next(options);
    } on Object catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  static bool _hasAuthorizationHeader(Map<String, dynamic> headers) {
    return headers.keys.any(
      (header) => header.toLowerCase() == _authorizationHeader.toLowerCase(),
    );
  }
}
