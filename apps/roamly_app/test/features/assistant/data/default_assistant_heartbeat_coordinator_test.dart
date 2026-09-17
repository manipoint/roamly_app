import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/data/models/assistant_incoming_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_ping_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_pong_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_ready_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/services/default_assistant_heartbeat_coordinator.dart';
import 'package:roamly_app/src/features/assistant/data/sources/assistant_socket_data_source.dart';
import 'package:roamly_networking/roamly_networking.dart';

const _connectionId = '00000000-0000-4000-8000-000000000001';

ConnectionReadyEventModel _ready({
  double heartbeatSeconds = 30,
  double idleSeconds = 90,
}) {
  return ConnectionReadyEventModel.fromJson({
    'version': 1,
    'type': 'connection.ready',
    'sent_at': '2026-09-17T12:00:00Z',
    'payload': <String, Object?>{
      'connection_id': _connectionId,
      'heartbeat_interval_seconds': heartbeatSeconds,
      'idle_timeout_seconds': idleSeconds,
      'max_message_bytes': 65536,
    },
  });
}

ConnectionPongEventModel _pong() {
  return ConnectionPongEventModel.fromJson({
    'version': 1,
    'type': 'connection.pong',
    'sent_at': '2026-09-17T12:00:01Z',
    'payload': <String, Object?>{},
  });
}

final class _ManualTimer implements Timer {
  _ManualTimer(this.duration, this._callback);

  final Duration duration;
  final void Function() _callback;

  bool _isActive = true;
  int _tick = 0;

  @override
  bool get isActive => _isActive;

  @override
  int get tick => _tick;

  @override
  void cancel() {
    _isActive = false;
  }

  void fire({bool includeCancelled = false}) {
    if (!_isActive && !includeCancelled) return;
    _isActive = false;
    _tick++;
    _callback();
  }
}

final class _ManualTimerFactory {
  final timers = <_ManualTimer>[];

  Timer create(Duration duration, void Function() callback) {
    final timer = _ManualTimer(duration, callback);
    timers.add(timer);
    return timer;
  }
}

final class _FakeAssistantSocketDataSource
    implements AssistantSocketDataSource {
  final _events = StreamController<AssistantIncomingEventModel>.broadcast(
    sync: true,
  );
  final _readiness = StreamController<bool>.broadcast(sync: true);

  final sentPings = <ConnectionPingEventModel>[];
  Object? sendError;
  int heartbeatTimeoutReports = 0;
  bool disposed = false;

  @override
  bool isReady = false;

  @override
  ConnectionReadyEventModel? readyConfiguration;

  @override
  Stream<AssistantIncomingEventModel> get events => _events.stream;

  @override
  Stream<bool> get readinessChanges => _readiness.stream;

  @override
  WebSocketStatusSnapshot get status => WebSocketStatusSnapshot(
    state: isReady
        ? WebSocketConnectionState.connected
        : WebSocketConnectionState.disconnected,
    generation: isReady ? 1 : 0,
  );

  @override
  Stream<WebSocketStatusSnapshot> get socketStates =>
      const Stream<WebSocketStatusSnapshot>.empty();

  @override
  void connect() {}

  @override
  Future<void> disconnect() async {
    emitNotReady();
  }

  @override
  void reportHeartbeatTimeout() {
    heartbeatTimeoutReports++;
    emitNotReady();
  }

  @override
  Future<void> sendPing(ConnectionPingEventModel ping) async {
    final error = sendError;
    if (error != null) throw error;
    sentPings.add(ping);
  }

  @override
  Future<void> sendTravelRequest(TravelRequestEventModel request) async {}

  void emitReady(ConnectionReadyEventModel configuration) {
    readyConfiguration = configuration;
    isReady = true;
    _readiness.add(true);
    _events.add(configuration);
  }

  void emitPong() {
    _events.add(_pong());
  }

  void emitNotReady() {
    if (!isReady && readyConfiguration == null) return;
    isReady = false;
    readyConfiguration = null;
    _readiness.add(false);
  }

  @override
  Future<void> dispose() async {
    if (disposed) return;
    disposed = true;
    await Future.wait<dynamic>([_events.close(), _readiness.close()]);
  }
}

Future<void> _flushMicrotasks() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeAssistantSocketDataSource dataSource;
  late _ManualTimerFactory timerFactory;
  late DefaultAssistantHeartbeatCoordinator coordinator;

  void createCoordinator() {
    dataSource = _FakeAssistantSocketDataSource();
    timerFactory = _ManualTimerFactory();
    coordinator = DefaultAssistantHeartbeatCoordinator(
      dataSource: dataSource,
      clock: () => DateTime.utc(2026, 9, 17, 12, 30),
      timerFactory: timerFactory.create,
    );
  }

  tearDown(() async {
    await coordinator.dispose();
    await dataSource.dispose();
  });

  test('late and duplicate start schedule one heartbeat', () {
    createCoordinator();
    dataSource.emitReady(_ready());

    coordinator.start();
    coordinator.start();

    expect(timerFactory.timers, hasLength(1));
    expect(timerFactory.timers.single.duration, const Duration(seconds: 30));
  });

  test('ping waits for pong before scheduling the next heartbeat', () async {
    createCoordinator();
    coordinator.start();
    dataSource.emitReady(_ready());

    timerFactory.timers.single.fire();
    await _flushMicrotasks();

    expect(dataSource.sentPings, hasLength(1));
    expect(
      dataSource.sentPings.single.sentAt,
      DateTime.utc(2026, 9, 17, 12, 30),
    );
    expect(timerFactory.timers, hasLength(2));
    expect(timerFactory.timers.last.duration, const Duration(seconds: 30));

    dataSource.emitPong();

    expect(timerFactory.timers[1].isActive, isFalse);
    expect(timerFactory.timers, hasLength(3));
    expect(timerFactory.timers.last.duration, const Duration(seconds: 30));
  });

  test('pong timeout invalidates the current connection', () async {
    createCoordinator();
    coordinator.start();
    dataSource.emitReady(_ready(heartbeatSeconds: 30, idleSeconds: 40));

    timerFactory.timers.single.fire();
    await _flushMicrotasks();
    expect(timerFactory.timers.last.duration, const Duration(seconds: 10));

    timerFactory.timers.last.fire();

    expect(dataSource.heartbeatTimeoutReports, 1);
    expect(dataSource.isReady, isFalse);
  });

  test('an old queued timer cannot send on a new ready cycle', () async {
    createCoordinator();
    coordinator.start();
    dataSource.emitReady(_ready());
    final oldTimer = timerFactory.timers.single;

    dataSource.emitNotReady();
    dataSource.emitReady(_ready());
    final currentTimer = timerFactory.timers.last;

    oldTimer.fire(includeCancelled: true);
    await _flushMicrotasks();
    expect(dataSource.sentPings, isEmpty);

    currentTimer.fire();
    await _flushMicrotasks();
    expect(dataSource.sentPings, hasLength(1));
  });

  test(
    'a ping send failure invalidates an otherwise ready connection',
    () async {
      createCoordinator();
      coordinator.start();
      dataSource.emitReady(_ready());
      dataSource.sendError = StateError('private transport detail');

      timerFactory.timers.single.fire();
      await _flushMicrotasks();

      expect(dataSource.heartbeatTimeoutReports, 1);
      expect(dataSource.isReady, isFalse);
    },
  );

  test('dispose is idempotent and invalidates queued timers', () async {
    createCoordinator();
    coordinator.start();
    dataSource.emitReady(_ready());
    final timer = timerFactory.timers.single;

    final first = coordinator.dispose();
    final second = coordinator.dispose();
    expect(identical(first, second), isTrue);
    await first;

    timer.fire(includeCancelled: true);
    await _flushMicrotasks();
    expect(dataSource.sentPings, isEmpty);
    expect(coordinator.start, throwsStateError);
  });
}
