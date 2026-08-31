import 'package:roamly_networking/roamly_networking.dart';
import 'package:test/test.dart';

const validTimeout = Duration(seconds: 10);

ApiConfig createConfig({
  Uri? baseUri,
  Duration connectTimeout = validTimeout,
  Duration sendTimeout = validTimeout,
  Duration receiveTimeout = validTimeout,
}) {
  return ApiConfig(
    baseUri: baseUri ?? Uri.parse('https://api.example.com/'),
    connectTimeout: connectTimeout,
    sendTimeout: sendTimeout,
    receiveTimeout: receiveTimeout,
  );
}

void main() {
  group('ApiConfig', () {
    test('preserves a valid HTTPS configuration', () {
      final baseUri = Uri.parse('https://api.example.com/');
      const connectTimeout = Duration(seconds: 5);
      const sendTimeout = Duration(seconds: 10);
      const receiveTimeout = Duration(seconds: 20);

      final config = ApiConfig(
        baseUri: baseUri,
        connectTimeout: connectTimeout,
        sendTimeout: sendTimeout,
        receiveTimeout: receiveTimeout,
      );

      expect(config.baseUri, baseUri);
      expect(config.connectTimeout, connectTimeout);
      expect(config.sendTimeout, sendTimeout);
      expect(config.receiveTimeout, receiveTimeout);
    });

    test('accepts HTTP for local development', () {
      final config = createConfig(baseUri: Uri.parse('http://127.0.0.1:8000/'));

      expect(config.baseUri, Uri.parse('http://127.0.0.1:8000/'));
    });

    test('adds a trailing slash to an authority-only URI', () {
      final config = createConfig(
        baseUri: Uri.parse('https://api.example.com'),
      );

      expect(config.baseUri, Uri.parse('https://api.example.com/'));
    });

    test('adds a trailing slash to a nested base path', () {
      final config = createConfig(
        baseUri: Uri.parse('https://api.example.com/api/v1'),
      );

      expect(config.baseUri, Uri.parse('https://api.example.com/api/v1/'));
    });

    test('preserves an existing trailing slash', () {
      final baseUri = Uri.parse('https://api.example.com/api/v1/');

      final config = createConfig(baseUri: baseUri);

      expect(config.baseUri, same(baseUri));
    });

    group('base URI validation', () {
      final invalidUris = <({String input, String reason})>[
        (input: '/api/v1', reason: 'http or https'),
        (input: 'ftp://api.example.com/', reason: 'http or https'),
        (input: 'https:///api/v1', reason: 'host'),
        (input: 'https://user:secret@api.example.com/', reason: 'credentials'),
        (input: 'https://api.example.com/?page=1', reason: 'query'),
        (input: 'https://api.example.com/#section', reason: 'fragment'),
      ];

      for (final invalidUri in invalidUris) {
        test('rejects ${invalidUri.reason}', () {
          expect(
            () => createConfig(baseUri: Uri.parse(invalidUri.input)),
            throwsA(
              isA<ArgumentError>().having(
                (error) => error.message.toString(),
                'message',
                contains(invalidUri.reason),
              ),
            ),
          );
        });
      }

      test('does not expose embedded credentials in the error', () {
        Object? thrownError;

        try {
          createConfig(
            baseUri: Uri.parse('https://user:secret-value@api.example.com/'),
          );
        } on Object catch (error) {
          thrownError = error;
        }

        expect(thrownError, isA<ArgumentError>());
        expect(thrownError.toString(), isNot(contains('secret-value')));
      });
    });

    group('timeout validation', () {
      final invalidTimeouts = [Duration.zero, const Duration(microseconds: -1)];

      for (final timeout in invalidTimeouts) {
        test('rejects invalid connectTimeout: $timeout', () {
          expect(
            () => createConfig(connectTimeout: timeout),
            throwsA(
              isA<ArgumentError>().having(
                (error) => error.name,
                'name',
                'connectTimeout',
              ),
            ),
          );
        });

        test('rejects invalid sendTimeout: $timeout', () {
          expect(
            () => createConfig(sendTimeout: timeout),
            throwsA(
              isA<ArgumentError>().having(
                (error) => error.name,
                'name',
                'sendTimeout',
              ),
            ),
          );
        });

        test('rejects invalid receiveTimeout: $timeout', () {
          expect(
            () => createConfig(receiveTimeout: timeout),
            throwsA(
              isA<ArgumentError>().having(
                (error) => error.name,
                'name',
                'receiveTimeout',
              ),
            ),
          );
        });
      }
    });
  });
}
