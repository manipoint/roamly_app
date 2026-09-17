import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/data/models/assistant_incoming_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_ping_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_pong_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_ready_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/services/assistant_heartbeat_coordinator.dart';
import 'package:roamly_app/src/features/assistant/data/services/default_assistant_realtime_session.dart';
import 'package:roamly_app/src/features/assistant/data/sources/assistant_socket_data_source.dart';
import 'package:roamly_networking/roamly_networking.dart';

const _clientMessageId = '00000000-0000-4000-8000-000000000001';

TravelRequestEventModel _request() {
  return TravelRequestEventModel(
    clientMessageId: _clientMessageId,
    message: 'Plan Lahore',
    sentAt: DateTime.utc(2026, 9, 17, 12),
  );
}

final class _FakeHeartbeatCoordinator implements AssistantHeartbeatCoordinator {
  _FakeHeartbeatCoordinator(this.calls);

  final List<String> calls;
  Object? disposeError;

  @override
  void start() {
    calls.add('heartbeat.start');
  }

  @override
  Future<void> dispose() async {
    calls.add('heartbeat.dispose');
    final error = disposeError;
    if (error != null) throw error;
  }
}

final class _FakeSocketDataSource implements AssistantSocketDataSource {
  _FakeSocketDataSource(this.calls);

  final List<String> calls;
  final eventController =
      StreamController<AssistantIncomingEventModel>.broadcast();
  final readinessController = StreamController<bool>.broadcast();
  final sentRequests = <TravelRequestEventModel>[];

  bool disposed = false;

  @override
  bool isReady = false;

  @override
  ConnectionReadyEventModel? readyConfiguration;

  @override
  Stream<AssistantIncomingEventModel> get events => eventController.stream;

  @override
  Stream<bool> get readinessChanges => readinessController.stream;

  @override
  WebSocketStatusSnapshot get status => WebSocketStatusSnapshot(
    state: isReady
        ? WebSocketConnectionState.connected
        : WebSocketConnectionState.disconnected,
    generation: 0,
  );

  @override
  Stream<WebSocketStatusSnapshot> get socketStates =>
      const Stream<WebSocketStatusSnapshot>.empty();

  @override
  void connect() {
    calls.add('socket.connect');
  }

  @override
  Future<void> disconnect() async {
    calls.add('socket.disconnect');
  }

  @override
  void reportHeartbeatTimeout() {
    calls.add('socket.heartbeatTimeout');
  }

  @override
  Future<void> sendPing(ConnectionPingEventModel ping) async {
    calls.add('socket.sendPing');
  }

  @override
  Future<void> sendTravelRequest(TravelRequestEventModel request) async {
    calls.add('socket.sendTravelRequest');
    sentRequests.add(request);
  }

  @override
  Future<void> dispose() async {
    calls.add('socket.dispose');
    disposed = true;
  }

  Future<void> closeControllers() async {
    await Future.wait<dynamic>([
      eventController.close(),
      readinessController.close(),
    ]);
  }
}

void main() {
  late List<String> calls;
  late _FakeSocketDataSource dataSource;
  late _FakeHeartbeatCoordinator heartbeat;
  late DefaultAssistantRealtimeSession session;

  setUp(() {
    calls = <String>[];
    dataSource = _FakeSocketDataSource(calls);
    heartbeat = _FakeHeartbeatCoordinator(calls);
    session = DefaultAssistantRealtimeSession(
      socketDataSource: dataSource,
      heartbeatCoordinator: heartbeat,
    );
  });

  tearDown(() async {
    try {
      await session.dispose();
    } on Object {
      // Individual failure tests assert the original disposal error.
    }
    await dataSource.closeControllers();
  });

  test('starts heartbeat before connecting the socket exactly once', () {
    session.connect();
    session.connect();

    expect(calls, <String>[
      'heartbeat.start',
      'socket.connect',
      'socket.connect',
    ]);
  });

  test('disconnect preserves heartbeat setup and allows reconnect', () async {
    session.connect();
    await session.disconnect();
    session.connect();

    expect(calls, <String>[
      'heartbeat.start',
      'socket.connect',
      'socket.disconnect',
      'socket.connect',
    ]);
  });

  test('delegates requests and observable socket state', () async {
    final request = _request();
    dataSource.isReady = true;
    final pong = ConnectionPongEventModel.fromJson({
      'version': 1,
      'type': 'connection.pong',
      'sent_at': '2026-09-17T12:00:00Z',
      'payload': <String, Object?>{},
    });

    final nextEvent = session.events.first;
    final nextReadiness = session.readinessChanges.first;
    dataSource.eventController.add(pong);
    dataSource.readinessController.add(true);

    expect(await nextEvent, same(pong));
    expect(await nextReadiness, isTrue);
    expect(session.isReady, isTrue);

    await session.sendTravelRequest(request);

    expect(dataSource.sentRequests, <TravelRequestEventModel>[request]);
    expect(calls, <String>['socket.sendTravelRequest']);
  });

  test(
    'dispose is idempotent and follows heartbeat then socket order',
    () async {
      final first = session.dispose();
      final second = session.dispose();

      expect(identical(first, second), isTrue);
      await first;

      expect(calls, <String>['heartbeat.dispose', 'socket.dispose']);
      expect(dataSource.disposed, isTrue);
    },
  );

  test('socket still disposes when heartbeat disposal fails', () async {
    heartbeat.disposeError = StateError('heartbeat cleanup failed');

    await expectLater(session.dispose(), throwsStateError);

    expect(calls, <String>['heartbeat.dispose', 'socket.dispose']);
    expect(dataSource.disposed, isTrue);
  });

  test('rejects lifecycle and send operations after dispose', () async {
    await session.dispose();

    expect(session.connect, throwsStateError);
    expect(() => session.disconnect(), throwsStateError);
    expect(() => session.sendTravelRequest(_request()), throwsStateError);
  });
}
