import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('uses the deployed Cloud Run API by default', () {
      final config = AppConfig.fromEnvironment();

      expect(
        config.apiConfig.baseUri,
        Uri.parse(
          'https://travel-assistant-api-752693246965.asia-south1.run.app/api/v1/',
        ),
      );
      expect(config.apiConfig.connectTimeout, const Duration(seconds: 15));
      expect(config.apiConfig.sendTimeout, const Duration(seconds: 15));
      expect(config.apiConfig.receiveTimeout, const Duration(seconds: 30));
      expect(
        config.assistantWebSocketUri,
        Uri.parse(
          'wss://travel-assistant-api-752693246965.asia-south1.run.app/ws/travel',
        ),
      );
    });

    test('normalizes an explicit API base URL', () {
      final config = AppConfig.fromValues(
        apiBaseUrl: '  https://api.roamly.test/v1  ',
        assistantWebSocketUrl: 'wss://api.roamly.test/ws/travel',
      );

      expect(
        config.apiConfig.baseUri,
        Uri.parse('https://api.roamly.test/v1/'),
      );
    });

    test('forwards explicit timeout values', () {
      final config = AppConfig.fromValues(
        apiBaseUrl: 'https://api.roamly.test',
        assistantWebSocketUrl: 'wss://api.roamly.test/ws/travel',
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
        () => AppConfig.fromValues(
          apiBaseUrl: '   ',
          assistantWebSocketUrl: 'wss://api.roamly.test/ws/travel',
        ),
        throwsArgumentError,
      );
    });

    test('delegates invalid URI validation to ApiConfig', () {
      expect(
        () => AppConfig.fromValues(
          apiBaseUrl: 'ftp://api.roamly.test',
          assistantWebSocketUrl: 'wss://api.roamly.test/ws/travel',
        ),
        throwsArgumentError,
      );
    });

    test('normalizes an explicit Assistant WebSocket URL', () {
      final config = AppConfig.fromValues(
        apiBaseUrl: 'https://api.roamly.test',
        assistantWebSocketUrl: '  wss://api.roamly.test/ws/travel  ',
      );

      expect(
        config.assistantWebSocketUri,
        Uri.parse('wss://api.roamly.test/ws/travel'),
      );
    });

    test('accepts ws for local development', () {
      final config = AppConfig.fromValues(
        apiBaseUrl: 'http://127.0.0.1:8000',
        assistantWebSocketUrl: 'ws://127.0.0.1:8000/ws/travel',
      );

      expect(
        config.assistantWebSocketUri,
        Uri.parse('ws://127.0.0.1:8000/ws/travel'),
      );
    });

    test('rejects an empty Assistant WebSocket URL', () {
      expect(
        () => AppConfig.fromValues(
          apiBaseUrl: 'https://api.roamly.test',
          assistantWebSocketUrl: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('rejects a non-WebSocket scheme', () {
      expect(
        () => AppConfig.fromValues(
          apiBaseUrl: 'https://api.roamly.test',
          assistantWebSocketUrl: 'https://api.roamly.test/ws/travel',
        ),
        throwsArgumentError,
      );
    });

    test('rejects a relative Assistant WebSocket URL', () {
      expect(
        () => AppConfig.fromValues(
          apiBaseUrl: 'https://api.roamly.test',
          assistantWebSocketUrl: '/ws/travel',
        ),
        throwsArgumentError,
      );
    });

    test('rejects credentials in the Assistant WebSocket URL', () {
      expect(
        () => AppConfig.fromValues(
          apiBaseUrl: 'https://api.roamly.test',
          assistantWebSocketUrl:
              'wss://username:password@api.roamly.test/ws/travel',
        ),
        throwsArgumentError,
      );
    });
  });
}
