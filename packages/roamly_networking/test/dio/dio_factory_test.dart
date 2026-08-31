import 'package:dio/dio.dart';
import 'package:roamly_networking/roamly_networking.dart';
import 'package:test/test.dart';

ApiConfig createConfig({
  Uri? baseUri,
  Duration connectTimeout = const Duration(seconds: 5),
  Duration sendTimeout = const Duration(seconds: 10),
  Duration receiveTimeout = const Duration(seconds: 20),
}) {
  return ApiConfig(
    baseUri: baseUri ?? Uri.parse('https://api.example.com/'),
    connectTimeout: connectTimeout,
    sendTimeout: sendTimeout,
    receiveTimeout: receiveTimeout,
  );
}

void main() {
  group('DioFactory', () {
    test('creates a Dio client from the API configuration', () {
      final config = createConfig(
        baseUri: Uri.parse('https://api.example.com/api/v1/'),
        connectTimeout: const Duration(seconds: 3),
        sendTimeout: const Duration(seconds: 7),
        receiveTimeout: const Duration(seconds: 11),
      );

      final dio = DioFactory.create(configuration: config);
      addTearDown(() => dio.close(force: true));

      expect(dio.options.baseUrl, 'https://api.example.com/api/v1/');
      expect(dio.options.connectTimeout, const Duration(seconds: 3));
      expect(dio.options.sendTimeout, const Duration(seconds: 7));
      expect(dio.options.receiveTimeout, const Duration(seconds: 11));
      expect(dio.options.responseType, ResponseType.json);
    });

    test('uses the normalized base URI supplied by ApiConfig', () {
      final config = createConfig(
        baseUri: Uri.parse('https://api.example.com/api/v1'),
      );

      final dio = DioFactory.create(configuration: config);
      addTearDown(() => dio.close(force: true));

      expect(dio.options.baseUrl, 'https://api.example.com/api/v1/');
    });

    test('requests JSON responses through the Accept header', () {
      final dio = DioFactory.create(configuration: createConfig());
      addTearDown(() => dio.close(force: true));

      expect(
        dio.options.headers[Headers.acceptHeader],
        Headers.jsonContentType,
      );
    });

    test('does not force a global request content type', () {
      final dio = DioFactory.create(configuration: createConfig());
      addTearDown(() => dio.close(force: true));

      expect(dio.options.contentType, isNull);
      expect(dio.options.headers, isNot(contains(Headers.contentTypeHeader)));
    });

    test('creates independent clients on separate calls', () {
      final config = createConfig();

      final first = DioFactory.create(configuration: config);
      final second = DioFactory.create(configuration: config);
      addTearDown(() {
        first.close(force: true);
        second.close(force: true);
      });

      expect(first, isNot(same(second)));
      expect(first.options, isNot(same(second.options)));
    });
  });
}
