import 'dart:async';
import 'dart:math';
import 'package:test/test.dart';
import 'package:roamly_networking/roamly_networking.dart';
import 'package:roamly_logging/roamly_logging.dart';

final class FakeConnection implements WebSocketConnection {
  final incoming = StreamController<String>();
  final ended = Completer<WebSocketCloseInfo>();
  final sent = <String>[];
  Object? closeError;
  int closes = 0;
  @override
  Stream<String> get message => incoming.stream;
  @override
  Future<WebSocketCloseInfo> get closed => ended.future;
  @override
  Future<void> send(String message) async {
    sent.add(message);
  }

  @override
  Future<void> close({int code = 1000, String? reason}) async {
    closes++;
    if (!ended.isCompleted) ended.complete(WebSocketCloseInfo(code: code));
    unawaited(incoming.close());
    if (closeError != null) throw closeError!;
  }
}

final class FakeTransport implements WebsocketTransport {
  int attempts = 0;
  final connections = <FakeConnection>[];
  final headersSeen = <Map<String, String>>[];
  Future<WebSocketConnection> Function()? open;
  @override
  Future<WebSocketConnection> connect({
    required Uri uri,
    required Duration connectTimeout,
    Map<String, String> headers = const {},
  }) async {
    attempts++;
    headersSeen.add(headers);
    if (open != null) return open!();
    final connection = FakeConnection();
    connections.add(connection);
    return connection;
  }
}

Future<void> eventually(bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) fail('Condition timed out');
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}

final class RecordingSink implements LogSink {
  final records = <LogRecord>[];
  bool failWrites = false;
  @override
  void write(LogRecord record) {
    if (failWrites) throw StateError('test sink failure');
    records.add(record);
  }
}

void main() {
  late FakeTransport transport;
  late RecordingSink sink;
  late WebsocketManager manager;
  late StreamSubscription<WebSocketMessage> subscription;
  final messages = <WebSocketMessage>[];
  var credentials = 0;
  setUp(() {
    transport = FakeTransport();
    sink = RecordingSink();
    messages.clear();
    credentials = 0;
    manager = WebsocketManager(
      transport: transport,
      logger: RoamlyLogger(name: 'test.networking', sink: sink),
      uri: Uri.parse('wss://example.com/ws'),
      headersProvider: () async => {'Authorization': 'test-${++credentials}'},
      stableConnectionDuration: const Duration(milliseconds: 10),
      reconnectPolicy: ReconnectPolicy(
        initialDelay: const Duration(milliseconds: 4),
        maxDelay: const Duration(milliseconds: 4),
        maxAttempts: 2,
        random: Random(42),
      ),
    );
    subscription = manager.messages.listen(messages.add);
  });
  tearDown(() async {
    await manager.dispose();
    await subscription.cancel();
  });

  test('logs lifecycle metadata without per-message noise', () async {
    manager.connect();
    manager.connect();
    await eventually(() => manager.isCurrent(manager.status.generation));
    expect(sink.records.map((record) => record.message), [
      'WebSocket connection attempt',
      'WebSocket connected',
    ]);
    expect(
      sink.records.every(
        (record) => record.loggerName == 'test.networking.websocket',
      ),
      isTrue,
    );
    final count = sink.records.length;
    await manager.send(
      'private outgoing chat',
      generation: manager.status.generation,
    );
    transport.connections.single.incoming.add('private incoming chat');
    await eventually(() => messages.isNotEmpty);
    expect(sink.records.length, count);
    await manager.disconnect();
    expect(
      sink.records.map((record) => record.message),
      containsAllInOrder([
        'WebSocket disconnect requested',
        'WebSocket disconnected',
      ]),
    );
  });

  test('logs retry delay and exhaustion with appropriate severity', () async {
    transport.open = () async => throw WebSocketFailure(
      kind: WebSocketFailureKind.rateLimited,
      httpStatusCode: 429,
    );
    manager.connect();
    await eventually(
      () =>
          manager.status.failure?.kind == WebSocketFailureKind.retriesExhausted,
    );
    final retries = sink.records
        .where((record) => record.message == 'WebSocket retry scheduled')
        .toList();
    expect(retries, hasLength(2));
    expect(retries.map((record) => record.fields['retry_attempt']), [1, 2]);
    for (final record in retries) {
      expect(record.level, LogLevel.warning);
      expect(record.fields['retry_delay_ms'], inInclusiveRange(2, 4));
      expect(record.fields['http_status_code'], 429);
      expect(record.fields['failure_kind'], 'rateLimited');
    }
    expect(sink.records.last.level, LogLevel.error);
    expect(sink.records.last.fields['failure_kind'], 'retriesExhausted');
  });

  test('logs auth rejection without scheduling retries', () async {
    transport.open = () async => throw WebSocketFailure(
      kind: WebSocketFailureKind.unauthorized,
      httpStatusCode: 401,
    );
    manager.connect();
    await eventually(
      () => manager.status.failure?.kind == WebSocketFailureKind.unauthorized,
    );
    expect(sink.records.last.level, LogLevel.warning);
    expect(sink.records.last.fields['http_status_code'], 401);
    expect(
      sink.records.where(
        (record) => record.message == 'WebSocket retry scheduled',
      ),
      isEmpty,
    );
  });

  test(
    'never logs credentials, endpoint, peer reason or raw cleanup error',
    () async {
      await manager.dispose();
      await subscription.cancel();
      sink.records.clear();
      manager = WebsocketManager(
        transport: transport,
        uri: Uri.parse('wss://example.com/ws?private=sensitive-endpoint'),
        headersProvider: () async => {
          'Authorization': 'Bearer sensitive-token',
        },
        logger: RoamlyLogger(name: 'test.networking', sink: sink),
      );
      subscription = manager.messages.listen(messages.add);
      manager.connect();
      await eventually(() => manager.isCurrent(manager.status.generation));
      await manager.send(
        'sensitive-outgoing',
        generation: manager.status.generation,
      );
      final socket = transport.connections.single;
      socket.incoming.add('sensitive-incoming');
      await eventually(() => messages.isNotEmpty);
      socket.closeError = StateError('sensitive-cleanup-error');
      socket.ended.complete(
        const WebSocketCloseInfo(code: 1008, reason: 'sensitive-peer-reason'),
      );
      await eventually(
        () => manager.status.state == WebSocketConnectionState.disconnected,
      );
      expect(
        sink.records.any((record) => record.fields['close_code'] == 1008),
        isTrue,
      );
      final cleanup = sink.records.singleWhere(
        (record) => record.message == 'WebSocket cleanup failed',
      );
      expect(cleanup.level, LogLevel.error);
      expect(cleanup.fields['failure_kind'], 'unknown');
      const allowed = {
        'generation',
        'retry_attempt',
        'retry_delay_ms',
        'failure_kind',
        'http_status_code',
        'close_code',
      };
      for (final record in sink.records) {
        expect(record.fields.keys.every(allowed.contains), isTrue);
        expect(record.error, isNull);
        expect(record.stackTrace, isNull);
        expect(
          '${record.message} ${record.fields}',
          isNot(contains('sensitive-')),
        );
        expect(
          '${record.message} ${record.fields}',
          isNot(contains('Authorization')),
        );
      }
    },
  );

  test(
    'raw connection exceptions are logged only as safe classifications',
    () async {
      transport.open = () async => throw StateError('private-token-in-error');
      manager.connect();
      await eventually(
        () => manager.status.failure?.kind == WebSocketFailureKind.unknown,
      );
      expect(sink.records.last.fields['failure_kind'], 'unknown');
      for (final record in sink.records) {
        expect(
          '${record.message} ${record.fields}',
          isNot(contains('private-token')),
        );
        expect(record.error, isNull);
        expect(record.stackTrace, isNull);
      }
    },
  );

  test('failing log sink cannot break connection or disposal', () async {
    sink.failWrites = true;
    manager.connect();
    await eventually(() => manager.isCurrent(manager.status.generation));
    await manager.send('hello', generation: manager.status.generation);
    await manager.dispose();
    expect(manager.status.state, WebSocketConnectionState.disposed);
    expect(transport.connections.single.closes, 1);
  });

  test('duplicate connect uses one socket and sends exactly once', () async {
    manager.connect();
    manager.connect();
    manager.connect();
    await eventually(
      () => manager.status.state == WebSocketConnectionState.connected,
    );
    expect(transport.attempts, 1);
    final generation = manager.status.generation;
    await manager.send('hello', generation: generation);
    transport.connections.single.incoming.add('reply');
    await eventually(() => messages.isNotEmpty);
    expect(messages.single.text, 'reply');
    expect(messages.single.generation, generation);
    expect(transport.connections.single.sent, ['hello']);
  });

  test(
    'disconnect waits for late connection and closes it without retry',
    () async {
      final pending = Completer<WebSocketConnection>();
      transport.open = () => pending.future;
      manager.connect();
      await eventually(() => transport.attempts == 1);
      final disconnected = manager.disconnect();
      expect(() => manager.connect(), throwsStateError);
      final late = FakeConnection();
      pending.complete(late);
      await disconnected;
      expect(late.closes, 1);
      expect(transport.attempts, 1);
      expect(manager.status.state, WebSocketConnectionState.disconnected);
    },
  );

  test(
    'reconnect refreshes headers and never replays a sent message',
    () async {
      manager.connect();
      await eventually(
        () =>
            transport.attempts == 1 &&
            manager.isCurrent(manager.status.generation),
      );
      final oldGeneration = manager.status.generation;
      await manager.send('once', generation: oldGeneration);
      manager.reportFailure(
        oldGeneration,
        WebSocketFailure(kind: WebSocketFailureKind.connection),
      );
      await eventually(
        () =>
            transport.attempts == 2 &&
            manager.isCurrent(manager.status.generation),
      );
      expect(transport.headersSeen[0], isNot(transport.headersSeen[1]));
      expect(transport.connections.last.sent, isEmpty);
      manager.reportFailure(
        oldGeneration,
        WebSocketFailure(kind: WebSocketFailureKind.protocol),
      );
      expect(manager.status.state, WebSocketConnectionState.connected);
      await expectLater(
        manager.send('stale', generation: oldGeneration),
        throwsA(isA<WebSocketFailure>()),
      );
    },
  );

  test('repeated transient failures exhaust the retry budget', () async {
    transport.open = () async =>
        throw WebSocketFailure(kind: WebSocketFailureKind.rateLimited);
    manager.connect();
    await eventually(
      () =>
          manager.status.failure?.kind == WebSocketFailureKind.retriesExhausted,
    );
    expect(transport.attempts, 3);
  });

  test('authorization failures stop automatic reconnect', () async {
    transport.open = () async =>
        throw WebSocketFailure(kind: WebSocketFailureKind.unauthorized);
    manager.connect();
    await eventually(
      () => manager.status.failure?.kind == WebSocketFailureKind.unauthorized,
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(transport.attempts, 1);
    expect(manager.status.state, WebSocketConnectionState.disconnected);
  });

  test('stable readiness resets the retry budget', () async {
    manager.connect();
    await eventually(() => manager.isCurrent(manager.status.generation));
    manager.reportFailure(
      manager.status.generation,
      WebSocketFailure(kind: WebSocketFailureKind.connection),
    );
    await eventually(
      () =>
          transport.attempts == 2 &&
          manager.isCurrent(manager.status.generation),
    );
    manager.markReady(manager.status.generation);
    await Future<void>.delayed(const Duration(milliseconds: 25));
    manager.reportFailure(
      manager.status.generation,
      WebSocketFailure(kind: WebSocketFailureKind.connection),
    );
    await eventually(
      () =>
          transport.attempts == 3 &&
          manager.isCurrent(manager.status.generation),
    );
    expect(manager.status.retryAttempt, 1);
  });

  test('flapping connections do not reset retries merely on connect', () async {
    manager.connect();
    for (var attempt = 1; attempt <= 3; attempt++) {
      await eventually(
        () =>
            transport.attempts == attempt &&
            manager.isCurrent(manager.status.generation),
      );
      manager.reportFailure(
        manager.status.generation,
        WebSocketFailure(kind: WebSocketFailureKind.connection),
      );
    }
    await eventually(
      () =>
          manager.status.failure?.kind == WebSocketFailureKind.retriesExhausted,
    );
    expect(transport.attempts, 3);
  });

  test('disconnect cancels scheduled retries', () async {
    transport.open = () async =>
        throw WebSocketFailure(kind: WebSocketFailureKind.connection);
    final scheduled = manager.socketStates.firstWhere(
      (state) => state.retryDelay != null,
    );
    manager.connect();
    await scheduled;
    await manager.disconnect();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(transport.attempts, 1);
  });

  test('transport error and close together schedule only one retry', () async {
    manager.connect();
    await eventually(() => manager.isCurrent(manager.status.generation));
    final socket = transport.connections.single;
    socket.incoming.addError(
      WebSocketFailure(kind: WebSocketFailureKind.connection),
    );
    socket.ended.complete(const WebSocketCloseInfo(code: 1006));
    await eventually(
      () =>
          transport.attempts == 2 &&
          manager.isCurrent(manager.status.generation),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(transport.attempts, 2);
  });

  test('dispose is idempotent and permanently prevents connect', () async {
    manager.connect();
    await eventually(() => manager.isCurrent(manager.status.generation));
    await Future.wait([manager.dispose(), manager.dispose()]);
    expect(manager.status.state, WebSocketConnectionState.disposed);
    expect(() => manager.connect(), throwsStateError);
  });
}
