import 'package:dio/dio.dart';
import 'package:roamly_networking/roamly_networking.dart';
import 'package:test/test.dart';

typedef _RequestInvocation = Future<Object?> Function(ApiClient client);

void main() {
  group('DioApiClient', () {
    final methodCases = <({String method, _RequestInvocation invoke})>[
      (method: 'GET', invoke: (client) => client.get('resources')),
      (method: 'POST', invoke: (client) => client.post('resources')),
      (method: 'PUT', invoke: (client) => client.put('resources/1')),
      (method: 'PATCH', invoke: (client) => client.patch('resources/1')),
      (method: 'DELETE', invoke: (client) => client.delete('resources/1')),
    ];

    for (final methodCase in methodCases) {
      test('sends ${methodCase.method} and returns response data', () async {
        late RequestOptions capturedRequest;
        final dio = _dioThatResolves(
          responseData: <String, Object?>{'result': 'ok'},
          onRequest: (request) => capturedRequest = request,
        );
        addTearDown(() => dio.close(force: true));
        final client = DioApiClient(dio: dio);

        final result = await methodCase.invoke(client);

        expect(capturedRequest.method, methodCase.method);
        expect(capturedRequest.path, startsWith('resources'));
        expect(result, <String, Object?>{'result': 'ok'});
      });
    }

    test('forwards body, query parameters, and request headers', () async {
      late RequestOptions capturedRequest;
      final dio = _dioThatResolves(
        responseData: null,
        onRequest: (request) => capturedRequest = request,
      );
      addTearDown(() => dio.close(force: true));
      final client = DioApiClient(dio: dio);

      await client.post(
        'resources',
        data: <String, Object?>{'name': 'Roamly'},
        queryParameters: <String, Object?>{'page': 2},
        headers: <String, Object?>{'X-Request-ID': 'request-123'},
      );

      expect(capturedRequest.data, <String, Object?>{'name': 'Roamly'});
      expect(capturedRequest.queryParameters, <String, Object?>{'page': 2});
      expect(capturedRequest.headers['X-Request-ID'], 'request-123');
    });

    test('propagates the original DioException', () async {
      final expectedException = DioException(
        requestOptions: RequestOptions(path: 'resources'),
        type: DioExceptionType.connectionError,
        message: 'Connection failed',
      );
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com/api/v1/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            handler.reject(expectedException);
          },
        ),
      );
      addTearDown(() => dio.close(force: true));
      final client = DioApiClient(dio: dio);

      await expectLater(
        client.get('resources'),
        throwsA(same(expectedException)),
      );
    });
  });
}

Dio _dioThatResolves({
  required Object? responseData,
  required void Function(RequestOptions request) onRequest,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com/api/v1/'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (request, handler) {
        onRequest(request);
        handler.resolve(
          Response<Object?>(
            requestOptions: request,
            statusCode: 200,
            data: responseData,
          ),
        );
      },
    ),
  );
  return dio;
}
