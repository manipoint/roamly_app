import 'package:roamly_networking/roamly_networking.dart';

/// Compile-time configuration required by the Roamly application.
final class AppConfig {
  const AppConfig({required this.apiConfig});
  static const String _defaultApiBaseUrl =
      'https://travel-assistant-api-752693246965.asia-south1.run.app/';

  /// Validated backend API configuration.
  final ApiConfig apiConfig;

  /// Builds configuration from Flutter `--dart-define` values.
  factory AppConfig.fromEnvironment() {
    const apiBaseUrl = String.fromEnvironment(
      'ROAMLY_API_BASE_URL',
      defaultValue: _defaultApiBaseUrl,
    );
    return AppConfig.fromValues(apiBaseUrl: apiBaseUrl);
  }

  /// Builds configuration from explicit values.
  ///
  /// This constructor is useful for tests and environment-specific launchers.
  factory AppConfig.fromValues({
    required String apiBaseUrl,
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
    );
  }
}
