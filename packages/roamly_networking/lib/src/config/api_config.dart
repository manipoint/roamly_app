/// Immutable HTTP transport configuration for the Roamly API.
final class ApiConfig {
  ApiConfig({
    required Uri baseUri,
    required Duration connectTimeout,
    required Duration sendTimeout,
    required Duration receiveTimeout,
  }) : baseUri = _validateAndNormalizeBaseUri(baseUri),
       connectTimeout = _validateTimeout(connectTimeout, 'connectTimeout'),
       sendTimeout = _validateTimeout(sendTimeout, 'sendTimeout'),
       receiveTimeout = _validateTimeout(receiveTimeout, 'receiveTimeout');

  /// Base URI used for backend API requests.
  ///
  /// The URI always ends with `/` so relative endpoint resolution remains
  /// predictable.
  final Uri baseUri;

  /// Maximum duration allowed while establishing a connection.
  final Duration connectTimeout;

  /// Maximum duration allowed while sending request data.
  final Duration sendTimeout;

  /// Maximum duration allowed while waiting for response data.
  final Duration receiveTimeout;

  static Uri _validateAndNormalizeBaseUri(Uri baseUri) {
    final scheme = baseUri.scheme.toLowerCase();

    if (scheme != 'http' && scheme != 'https') {
      throw ArgumentError('baseUri must use the http or https scheme');
    }
    if (baseUri.host.isEmpty) {
      throw ArgumentError('baseUri must contain a host');
    }
    if (baseUri.userInfo.isNotEmpty) {
      throw ArgumentError('baseUri must not contain credentials');
    }
    if (baseUri.hasQuery) {
      throw ArgumentError('baseUri must not contain query parameters');
    }
    if (baseUri.hasFragment) {
      throw ArgumentError('baseUri must not contain a fragment');
    }
    if (baseUri.path.endsWith('/')) {
      return baseUri;
    }
    return Uri.parse('${baseUri.toString()}/');
  }

  static Duration _validateTimeout(Duration value, String parameterName) {
    if (value <= Duration.zero) {
      throw ArgumentError.value(
        value,
        parameterName,
        "must be greater than Duration.zero",
      );
    }
    return value;
  }
}
