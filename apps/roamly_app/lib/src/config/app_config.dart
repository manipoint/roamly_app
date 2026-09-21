import 'package:roamly_networking/roamly_networking.dart';

/// Compile-time configuration required by the Roamly application.
final class AppConfig {
  const AppConfig({
    required this.apiConfig,
    required this.assistantWebSocketUri,
  });
  static const String _defaultApiBaseUrl =
      'https://travel-assistant-api-752693246965.asia-south1.run.app/api/v1/';
  static const String _defaultAssistantWebSocketUrl =
      'wss://travel-assistant-api-752693246965.asia-south1.run.app/ws/travel';

  /// Validated backend API configuration.
  final ApiConfig apiConfig;
  final Uri assistantWebSocketUri;

  /// Builds configuration from Flutter `--dart-define` values.
  factory AppConfig.fromEnvironment() {
    const apiBaseUrl = String.fromEnvironment(
      'ROAMLY_API_BASE_URL',
      defaultValue: _defaultApiBaseUrl,
    );
    const assistantWebSocketUrl = String.fromEnvironment(
      'ROAMLY_ASSISTANT_WS_URL',
      defaultValue: _defaultAssistantWebSocketUrl,
    );
    return AppConfig.fromValues(
      apiBaseUrl: apiBaseUrl,
      assistantWebSocketUrl: assistantWebSocketUrl,
    );
  }

  /// Builds configuration from explicit values.
  ///
  /// This constructor is useful for tests and environment-specific launchers.
  factory AppConfig.fromValues({
    required String apiBaseUrl,
    required String assistantWebSocketUrl,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration sendTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) {
    final normalizedApiBaseUrl = apiBaseUrl.trim();
    if (normalizedApiBaseUrl.isEmpty) {
      throw ArgumentError.value(apiBaseUrl, 'apiBaseUrl', 'must not be empty');
    }
    return AppConfig(
      apiConfig: ApiConfig(
        baseUri: Uri.parse(normalizedApiBaseUrl),
        connectTimeout: connectTimeout,
        sendTimeout: sendTimeout,
        receiveTimeout: receiveTimeout,
      ),
      assistantWebSocketUri: _parseWebSocketUri(assistantWebSocketUrl),
    );
  }

  static Uri _parseWebSocketUri(String value) {
    final normalizedValue = value.trim();

    if (normalizedValue.isEmpty) {
      throw ArgumentError.value(
        value,
        'assistantWebSocketUrl',
        'must not be empty',
      );
    }

    final uri = Uri.tryParse(normalizedValue);
    final hasSupportedScheme = uri?.scheme == 'ws' || uri?.scheme == 'wss';

    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !hasSupportedScheme) {
      throw ArgumentError.value(
        value,
        'assistantWebSocketUrl',
        'must be an absolute ws or wss URL',
      );
    }

    if (uri.userInfo.isNotEmpty) {
      throw ArgumentError.value(
        value,
        'assistantWebSocketUrl',
        'must not contain credentials',
      );
    }

    return uri;
  }
}
