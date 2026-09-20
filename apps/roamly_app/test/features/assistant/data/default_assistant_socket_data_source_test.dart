import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/data/models/assistant_incoming_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_ready_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_accepted_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_event_model.dart';
import 'package:roamly_app/src/features/assistant/domain/policies/assistant_policy.dart';
import 'package:roamly_app/src/features/assistant/data/sources/default_assistant_socket_data_source.dart';
import 'package:roamly_networking/roamly_networking.dart';

const _clientId = '00000000-0000-4000-8000-000000000001';
const _conversationId = '00000000-0000-4000-8000-000000000002';
const _connectionId = '00000000-0000-4000-8000-000000000003';

final class _FakeConnection implements WebSocketConnection {
  final incoming = StreamController<String>();
  final closedCompleter = Completer<WebSocketCloseInfo>();
  final sent = <String>[];
  var closeCount = 0;

  @override
  Stream<String> get message => incoming.stream;

  @override
  Future<WebSocketCloseInfo> get closed => closedCompleter.future;

  @override
  Future<void> send(String message) async {
    sent.add(message);
  }

  @override
  Future<void> close({int code = 1000, String? reason}) async {
    closeCount++;
    if (!closedCompleter.isCompleted) {
      closedCompleter.complete(WebSocketCloseInfo(code: code, reason: reason));
    }
    if (!incoming.isClosed) await incoming.close();
  }
}

final class _FakeTransport implements WebsocketTransport {
  final connections = <_FakeConnection>[];

  @override
  Future<WebSocketConnection> connect({
    required Uri uri,
    required Duration connectTimeout,
    Map<String, String> headers = const {},
  }) async {
    final connection = _FakeConnection();
    connections.add(connection);
    return connection;
  }
}

Map<String, Object?> _readyEvent({required int maxMessageBytes}) => {
  'version': 1,
  'type': 'connection.ready',
  'sent_at': '2026-09-17T12:00:00Z',
  'payload': <String, Object?>{
    'connection_id': _connectionId,
    'heartbeat_interval_seconds': 30,
    'idle_timeout_seconds': 90,
    'max_message_bytes': maxMessageBytes,
  },
};

Map<String, Object?> _acceptedEvent() => {
  'version': 1,
  'type': 'travel.request.accepted',
  'sent_at': '2026-09-17T12:00:01Z',
  'payload': <String, Object?>{
    'client_message_id': _clientId,
    'conversation_id': _conversationId,
  },
};

TravelRequestEventModel _request(String message) {
  return TravelRequestEventModel(
    clientMessageId: _clientId,
    conversationId: _conversationId,
    message: message,
    sentAt: DateTime.utc(2026, 9, 17, 12),
  );
}

Future<void> _eventually(bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition timed out.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}

void main() {
  late _FakeTransport transport;
  late WebsocketManager manager;
  late DefaultAssistantSocketDataSource dataSource;
  late StreamSubscription<AssistantIncomingEventModel> eventSubscription;
  late StreamSubscription<bool> readinessSubscription;
  late List<AssistantIncomingEventModel> events;
  late List<Object> errors;
  late List<bool> readiness;

  void createDataSource({
    Duration readyTimeout = AssistantPolicy.defaultReadyTimeout,
    int maximumIncomingMessageBytes =
        AssistantPolicy.maximumNegotiatedOutgoingMessageBytes,
    int reconnectAttempts = 0,
  }) {
    transport = _FakeTransport();
    manager = WebsocketManager(
      transport: transport,
      uri: Uri.parse('wss://example.test/ws/travel'),
      headersProvider: () async => const <String, String>{},
      reconnectPolicy: ReconnectPolicy(
        initialDelay: const Duration(milliseconds: 1),
        maxDelay: const Duration(milliseconds: 1),
        maxAttempts: reconnectAttempts,
      ),
    );
    dataSource = DefaultAssistantSocketDataSource(
      manager: manager,
      readyTimeout: readyTimeout,
      maximumIncomingMessageBytes: maximumIncomingMessageBytes,
    );
    events = <AssistantIncomingEventModel>[];
    errors = <Object>[];
    readiness = <bool>[];
    eventSubscription = dataSource.events.listen(
      events.add,
      onError: (Object error, StackTrace _) => errors.add(error),
    );
    readinessSubscription = dataSource.readinessChanges.listen(readiness.add);
  }

  Future<_FakeConnection> connect() async {
    dataSource.connect();
    await _eventually(
      () =>
          transport.connections.isNotEmpty &&
          manager.status.state == WebSocketConnectionState.connected,
    );
    return transport.connections.single;
  }

  Future<_FakeConnection> connectAndBecomeReady({
    int maxMessageBytes = 65536,
  }) async {
    final connection = await connect();
    connection.incoming.add(
      jsonEncode(_readyEvent(maxMessageBytes: maxMessageBytes)),
    );
    await _eventually(() => dataSource.isReady);
    return connection;
  }

  tearDown(() async {
    await dataSource.dispose();
    await eventSubscription.cancel();
    await readinessSubscription.cancel();
  });

  test(
    'becomes ready before publishing and sends on that generation',
    () async {
      createDataSource();
      final connection = await connectAndBecomeReady();

      expect(dataSource.isReady, isTrue);
      expect(readiness, <bool>[true]);
      expect(events.single, isA<ConnectionReadyEventModel>());

      await dataSource.sendTravelRequest(_request('Plan Lahore'));
      expect(connection.sent, hasLength(1));
      expect(jsonDecode(connection.sent.single), isA<Map<String, dynamic>>());

      await dataSource.disconnect();
      expect(dataSource.isReady, isFalse);
      expect(readiness, <bool>[true, false]);
    },
  );

  test('rejects sends until the Assistant handshake is ready', () async {
    createDataSource();
    await connect();

    await expectLater(
      dataSource.sendTravelRequest(_request('Plan Lahore')),
      throwsA(
        isA<WebSocketFailure>().having(
          (failure) => failure.kind,
          'kind',
          WebSocketFailureKind.connection,
        ),
      ),
    );
  });

  test('rejects pre-ready and malformed events but keeps processing', () async {
    createDataSource();
    final connection = await connect();

    connection.incoming.add(jsonEncode(_acceptedEvent()));
    connection.incoming.add('private malformed payload');
    connection.incoming.add(jsonEncode(_readyEvent(maxMessageBytes: 65536)));
    connection.incoming.add(jsonEncode(_acceptedEvent()));

    await _eventually(() => events.length == 2 && errors.length == 2);
    expect(events.first, isA<ConnectionReadyEventModel>());
    expect(events.last, isA<TravelRequestAcceptedEventModel>());
    expect(errors, everyElement(isA<FormatException>()));
    expect(errors.join(' '), isNot(contains('private malformed payload')));
  });

  test('rejects a duplicate ready event without replacing readiness', () async {
    createDataSource();
    final connection = await connectAndBecomeReady();

    connection.incoming.add(jsonEncode(_readyEvent(maxMessageBytes: 32768)));

    await _eventually(() => errors.isNotEmpty);
    expect(errors.single, isA<FormatException>());
    expect(events.whereType<ConnectionReadyEventModel>(), hasLength(1));
    expect(dataSource.isReady, isTrue);
  });

  test(
    'terminates the generation when an incoming frame is oversized',
    () async {
      createDataSource(maximumIncomingMessageBytes: 32);
      final connection = await connect();

      connection.incoming.add('x' * 33);

      await _eventually(() => errors.isNotEmpty);
      expect(
        errors.single,
        isA<WebSocketFailure>().having(
          (failure) => failure.kind,
          'kind',
          WebSocketFailureKind.messageTooLarge,
        ),
      );
      await _eventually(
        () => manager.status.state == WebSocketConnectionState.disconnected,
      );
    },
  );

  test('enforces the server outbound limit using UTF-8 bytes', () async {
    createDataSource();
    final request = _request('🌍');
    final encoded = jsonEncode(request.toJson());
    await connectAndBecomeReady(maxMessageBytes: encoded.length);

    expect(utf8.encode(encoded).length, greaterThan(encoded.length));
    await expectLater(
      dataSource.sendTravelRequest(request),
      throwsA(
        isA<WebSocketFailure>().having(
          (failure) => failure.kind,
          'kind',
          WebSocketFailureKind.messageTooLarge,
        ),
      ),
    );
  });

  test('fails and disconnects when ready handshake times out', () async {
    createDataSource(readyTimeout: const Duration(milliseconds: 20));
    await connect();

    await _eventually(
      () => errors.whereType<WebSocketFailure>().any(
        (failure) => failure.kind == WebSocketFailureKind.timeout,
      ),
    );
    await _eventually(
      () => manager.status.state == WebSocketConnectionState.disconnected,
    );
    expect(dataSource.isReady, isFalse);
  });

  test('heartbeat timeout invalidates the current ready generation', () async {
    createDataSource();
    await connectAndBecomeReady();

    expect(dataSource.readyConfiguration, isNotNull);
    dataSource.reportHeartbeatTimeout();

    expect(dataSource.isReady, isFalse);
    expect(dataSource.readyConfiguration, isNull);
    await _eventually(
      () => manager.status.state == WebSocketConnectionState.disconnected,
    );
  });

  test(
    'reconnect clears readiness and requires the new generation ready',
    () async {
      createDataSource(reconnectAttempts: 1);
      await connectAndBecomeReady();
      final firstGeneration = manager.status.generation;

      manager.reportFailure(
        firstGeneration,
        WebSocketFailure(kind: WebSocketFailureKind.connection),
      );
      await _eventually(
        () =>
            transport.connections.length == 2 &&
            manager.status.generation != firstGeneration &&
            manager.status.state == WebSocketConnectionState.connected,
      );

      expect(dataSource.isReady, isFalse);
      await expectLater(
        dataSource.sendTravelRequest(_request('Plan Lahore')),
        throwsA(isA<WebSocketFailure>()),
      );

      final secondConnection = transport.connections.last;
      secondConnection.incoming.add(jsonEncode(_acceptedEvent()));
      await _eventually(() => errors.isNotEmpty);
      expect(events.whereType<TravelRequestAcceptedEventModel>(), isEmpty);

      secondConnection.incoming.add(
        jsonEncode(_readyEvent(maxMessageBytes: 65536)),
      );
      await _eventually(() => dataSource.isReady);
      expect(manager.status.generation, isNot(firstGeneration));
    },
  );

  test('paused event listeners do not block disposal', () async {
    createDataSource();
    final paused = dataSource.events.listen((_) {})..pause();
    await connectAndBecomeReady();

    await dataSource.dispose().timeout(const Duration(seconds: 1));
    await paused.cancel();
  });

  test('dispose is idempotent and rejects later operations', () async {
    createDataSource();
    final connection = await connectAndBecomeReady();

    final first = dataSource.dispose();
    final second = dataSource.dispose();
    expect(identical(first, second), isTrue);
    await first;

    expect(connection.closeCount, 1);
    expect(dataSource.isReady, isFalse);
    expect(dataSource.connect, throwsStateError);
    await expectLater(
      dataSource.sendTravelRequest(_request('Plan Lahore')),
      throwsStateError,
    );
  });
}
