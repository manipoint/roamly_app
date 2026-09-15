import 'dart:async';
import 'dart:io';

import 'package:roamly_networking/src/websocket/io_websocket_transport.dart';
import 'package:roamly_networking/src/websocket/websocket_failure.dart';
import 'package:test/test.dart';

void main() {
  const transport = IoWebSocketTransport();
  const deadline = Duration(seconds: 3);
  late HttpServer server;
  late Uri uri;
  late StreamIterator<HttpRequest> requests;
  final peers = <WebSocket>[];

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    uri = Uri.parse('ws://127.0.0.1:${server.port}/ws/travel');
    requests = StreamIterator(server);
  });

  tearDown(() async {
    for (final peer in peers) {
      await peer.close().timeout(const Duration(seconds: 7));
    }
    peers.clear();
    await server.close(force: true);
    await requests.cancel();
  });

  Future<HttpRequest> nextRequest() async {
    expect(await requests.moveNext().timeout(deadline), isTrue);
    return requests.current;
  }

  Future<WebSocket> accept() async {
    final peer = await WebSocketTransformer.upgrade(await nextRequest());
    peers.add(peer);
    return peer;
  }

  TypeMatcher<WebSocketFailure> failure(WebSocketFailureKind kind) =>
      isA<WebSocketFailure>().having((error) => error.kind, 'kind', kind);

  test(
    'sends authorization header and exchanges ordered text frames',
    () async {
      final connecting = transport.connect(
        uri: uri,
        connectTimeout: deadline,
        headers: {'Authorization': 'Bearer local-test-only'},
      );
      final request = await nextRequest();
      expect(request.headers.value('authorization'), 'Bearer local-test-only');
      final peer = await WebSocketTransformer.upgrade(request);
      peers.add(peer);
      final peerMessages = StreamIterator(peer);
      final connection = await connecting;
      final incoming = StreamIterator(connection.message);

      await connection.send('hello');
      expect(await peerMessages.moveNext().timeout(deadline), isTrue);
      expect(peerMessages.current, 'hello');
      peer.add('first');
      peer.add('second');
      expect(await incoming.moveNext().timeout(deadline), isTrue);
      expect(incoming.current, 'first');
      expect(await incoming.moveNext().timeout(deadline), isTrue);
      expect(incoming.current, 'second');
      await connection.close();
      await incoming.cancel();
      await peerMessages.cancel();
    },
  );

  test(
    'remote close completes once and repeated local close is safe',
    () async {
      final connecting = transport.connect(uri: uri, connectTimeout: deadline);
      final peer = await accept();
      peer.listen((_) {});
      final connection = await connecting;
      final ended = expectLater(connection.message, emitsDone);
      await peer.close(WebSocketStatus.goingAway, 'test shutdown');
      final info = await connection.closed.timeout(deadline);
      expect(info.code, WebSocketStatus.goingAway);
      expect(info.reason, 'test shutdown');
      await ended;
      await connection.close();
      await connection.close();
    },
  );

  test('concurrent close is safe and sends after close fail', () async {
    final connecting = transport.connect(uri: uri, connectTimeout: deadline);
    final peer = await accept();
    peer.listen((_) {});
    final connection = await connecting;
    final ended = expectLater(connection.message, emitsDone);
    await Future.wait([connection.close(), connection.close()]);
    await ended;
    await expectLater(
      connection.send('too late'),
      throwsA(failure(WebSocketFailureKind.connection)),
    );
  });

  test('rejects binary data with a typed failure and closes', () async {
    final connecting = transport.connect(uri: uri, connectTimeout: deadline);
    final peer = await accept();
    peer.listen((_) {});
    final connection = await connecting;
    final result = expectLater(
      connection.message,
      emitsInOrder([
        emitsError(failure(WebSocketFailureKind.protocol)),
        emitsDone,
      ]),
    );
    peer.add([1, 2, 3]);
    await result;
    await connection.closed.timeout(deadline);
  });

  test('cancelling the message listener closes the connection', () async {
    final connecting = transport.connect(uri: uri, connectTimeout: deadline);
    final peer = await accept();
    peer.listen((_) {});
    final connection = await connecting;
    final subscription = connection.message.listen((_) {});
    await subscription.cancel().timeout(deadline);
    await connection.closed.timeout(deadline);
    await expectLater(
      connection.send('too late'),
      throwsA(failure(WebSocketFailureKind.connection)),
    );
  });

  test('times out an HTTP upgrade that never responds', () async {
    final result = expectLater(
      transport.connect(
        uri: uri,
        connectTimeout: const Duration(milliseconds: 150),
      ),
      throwsA(failure(WebSocketFailureKind.timeout)),
    );
    await nextRequest();
    await result.timeout(deadline);
  });

  test('reports refused TCP connection as a retryable failure', () async {
    await server.close(force: true);
    await expectLater(
      transport.connect(uri: uri, connectTimeout: deadline),
      throwsA(
        failure(
          WebSocketFailureKind.connection,
        ).having((error) => error.isRetryable, 'isRetryable', isTrue),
      ),
    );
  });

  test('classifies HTTP 503 as transient for reconnect', () async {
    final result = expectLater(
      transport.connect(uri: uri, connectTimeout: deadline),
      throwsA(failure(WebSocketFailureKind.connection)),
    );
    final request = await nextRequest();
    request.response.statusCode = HttpStatus.serviceUnavailable;
    await request.response.close();
    await result;
  });

  for (final invalid in [
    'https://example.com/ws',
    'ws:///ws',
    'ws://user:password@example.com/ws',
    'ws://example.com/ws#fragment',
  ]) {
    test('rejects invalid endpoint: $invalid', () async {
      await expectLater(
        transport.connect(uri: Uri.parse(invalid), connectTimeout: deadline),
        throwsArgumentError,
      );
    });
  }

  for (final timeout in [Duration.zero, const Duration(seconds: -1)]) {
    test('rejects non-positive connection timeout: $timeout', () async {
      await expectLater(
        transport.connect(uri: uri, connectTimeout: timeout),
        throwsArgumentError,
      );
    });
  }
}
