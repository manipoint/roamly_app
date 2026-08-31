import 'package:dio/dio.dart';
import 'package:roamly_networking/roamly_networking.dart';
import 'package:test/test.dart';

const authorizationHeader = 'Authorization';

final class FakeAccessTokenProvider implements AccessTokenProvider {
  FakeAccessTokenProvider({this.token, this.error});

  final String? token;
  final Object? error;
  int calls = 0;

  @override
  Future<String?> readAccessToken() async {
    calls++;

    if (error case final error?) {
      throw error;
    }

    return token;
  }
}

final class RecordingRequestHandler extends RequestInterceptorHandler {
  int nextCalls = 0;
  int rejectCalls = 0;
  RequestOptions? forwardedOptions;
  DioException? rejectedError;

  @override
  void next(RequestOptions requestOptions) {
    nextCalls++;
    forwardedOptions = requestOptions;
  }

  @override
  void reject(
    DioException error, [
    bool callFollowingErrorInterceptor = false,
  ]) {
    rejectCalls++;
    rejectedError = error;
  }
}

Future<void> runInterceptor({
  required BearerTokenInterceptor interceptor,
  required RequestOptions options,
  required RecordingRequestHandler handler,
}) async {
  interceptor.onRequest(options, handler);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('BearerTokenInterceptor', () {
    test('adds a bearer authorization header', () async {
      final provider = FakeAccessTokenProvider(token: 'access-token');
      final interceptor = BearerTokenInterceptor(provider);
      final options = RequestOptions(path: '/trips');
      final handler = RecordingRequestHandler();

      await runInterceptor(
        interceptor: interceptor,
        options: options,
        handler: handler,
      );

      expect(provider.calls, 1);
      expect(handler.nextCalls, 1);
      expect(handler.rejectCalls, 0);
      expect(
        handler.forwardedOptions?.headers[authorizationHeader],
        'Bearer access-token',
      );
      expect(
        handler.forwardedOptions?.headers,
        isNot(contains(Headers.wwwAuthenticateHeader)),
      );
    });

    test('trims surrounding access-token whitespace', () async {
      final provider = FakeAccessTokenProvider(token: '  access-token  ');
      final interceptor = BearerTokenInterceptor(provider);
      final handler = RecordingRequestHandler();

      await runInterceptor(
        interceptor: interceptor,
        options: RequestOptions(path: '/trips'),
        handler: handler,
      );

      expect(
        handler.forwardedOptions?.headers[authorizationHeader],
        'Bearer access-token',
      );
    });

    for (final token in <String?>[null, '', '   ']) {
      test(
        'continues without authorization for token: ${token ?? 'null'}',
        () async {
          final provider = FakeAccessTokenProvider(token: token);
          final interceptor = BearerTokenInterceptor(provider);
          final handler = RecordingRequestHandler();

          await runInterceptor(
            interceptor: interceptor,
            options: RequestOptions(path: '/trips'),
            handler: handler,
          );

          expect(provider.calls, 1);
          expect(handler.nextCalls, 1);
          expect(handler.rejectCalls, 0);
          expect(
            handler.forwardedOptions?.headers,
            isNot(contains(authorizationHeader)),
          );
        },
      );
    }

    test('preserves an explicitly supplied authorization header', () async {
      final provider = FakeAccessTokenProvider(token: 'stored-token');
      final interceptor = BearerTokenInterceptor(provider);
      final options = RequestOptions(
        path: '/custom-auth',
        headers: {authorizationHeader: 'Custom credential'},
      );
      final handler = RecordingRequestHandler();

      await runInterceptor(
        interceptor: interceptor,
        options: options,
        handler: handler,
      );

      expect(provider.calls, 0);
      expect(handler.nextCalls, 1);
      expect(handler.rejectCalls, 0);
      expect(
        handler.forwardedOptions?.headers[authorizationHeader],
        'Custom credential',
      );
    });

    test('recognizes an authorization header case-insensitively', () async {
      final provider = FakeAccessTokenProvider(token: 'stored-token');
      final interceptor = BearerTokenInterceptor(provider);
      final options = RequestOptions(
        path: '/custom-auth',
        headers: {'authorization': 'Custom credential'},
      );
      final handler = RecordingRequestHandler();

      await runInterceptor(
        interceptor: interceptor,
        options: options,
        handler: handler,
      );

      expect(provider.calls, 0);
      expect(handler.nextCalls, 1);
      expect(handler.rejectCalls, 0);
      expect(
        handler.forwardedOptions?.headers['authorization'],
        'Custom credential',
      );
    });

    test('rejects instead of sending when token access fails', () async {
      final storageError = StateError('secure storage unavailable');
      final provider = FakeAccessTokenProvider(error: storageError);
      final interceptor = BearerTokenInterceptor(provider);
      final options = RequestOptions(path: '/trips');
      final handler = RecordingRequestHandler();

      await runInterceptor(
        interceptor: interceptor,
        options: options,
        handler: handler,
      );

      expect(provider.calls, 1);
      expect(handler.nextCalls, 0);
      expect(handler.rejectCalls, 1);
      expect(handler.rejectedError?.requestOptions, same(options));
      expect(handler.rejectedError?.type, DioExceptionType.unknown);
      expect(handler.rejectedError?.error, same(storageError));
    });
  });
}
