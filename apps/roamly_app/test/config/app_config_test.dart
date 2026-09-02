import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('uses the deployed Cloud Run API by default', () {
      final config = AppConfig.fromEnvironment();

      expect(
        config.apiConfig.baseUri,
        Uri.parse(
          'https://travel-assistant-api-752693246965.asia-south1.run.app/',
        ),
      );
      expect(config.apiConfig.connectTimeout, const Duration(seconds: 15));
      expect(config.apiConfig.sendTimeout, const Duration(seconds: 15));
      expect(config.apiConfig.receiveTimeout, const Duration(seconds: 30));
    });

    test('normalizes an explicit API base URL', () {
      final config = AppConfig.fromValues(
        apiBaseUrl: '  https://api.roamly.test/v1  ',
      );

      expect(
        config.apiConfig.baseUri,
        Uri.parse('https://api.roamly.test/v1/'),
      );
    });

    test('forwards explicit timeout values', () {
      final config = AppConfig.fromValues(
        apiBaseUrl: 'https://api.roamly.test',
        connectTimeout: const Duration(seconds: 3),
        sendTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 5),
      );

      expect(config.apiConfig.connectTimeout, const Duration(seconds: 3));
      expect(config.apiConfig.sendTimeout, const Duration(seconds: 4));
      expect(config.apiConfig.receiveTimeout, const Duration(seconds: 5));
    });

    test('rejects an empty API base URL', () {
      expect(
        () => AppConfig.fromValues(apiBaseUrl: '   '),
        throwsArgumentError,
      );
    });

    test('delegates invalid URI validation to ApiConfig', () {
      expect(
        () => AppConfig.fromValues(apiBaseUrl: 'ftp://api.roamly.test'),
        throwsArgumentError,
      );
    });
  });
}
