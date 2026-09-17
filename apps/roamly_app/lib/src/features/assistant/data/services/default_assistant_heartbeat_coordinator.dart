import 'dart:async';

import '../models/assistant_incoming_event_model.dart';
import '../models/connection_ping_event_model.dart';
import '../models/connection_pong_event_model.dart';
import '../models/connection_ready_event_model.dart';
import '../sources/assistant_socket_data_source.dart';
import 'assistant_heartbeat_coordinator.dart';

typedef AssistantClock = DateTime Function();
typedef AssistantTimerFactory =
    Timer Function(Duration duration, void Function() callback);

final class DefaultAssistantHeartbeatCoordinator
    implements AssistantHeartbeatCoordinator {
  DefaultAssistantHeartbeatCoordinator({
    required AssistantSocketDataSource dataSource,
    AssistantClock? clock,
    AssistantTimerFactory? timerFactory,
  }) : _dataSource = dataSource,
       _clock = clock ?? DateTime.now,
       _timerFactory = timerFactory ?? Timer.new;

  final AssistantSocketDataSource _dataSource;
  final AssistantClock _clock;
  final AssistantTimerFactory _timerFactory;

  StreamSubscription<AssistantIncomingEventModel>? _eventSubscription;
  StreamSubscription<bool>? _readinessSubscription;

  Timer? _heartbeatTimer;
  Timer? _pongTimer;

  Duration? _heartbeatInterval;
  Duration? _pongTimeout;

  int _cycle = 0;
  bool _started = false;
  bool _disposed = false;
  bool _awaitingPong = false;
  Future<void>? _disposeFuture;

  @override
  void start() {
    if (_disposed) {
      throw StateError('AssistantHeartbeatCoordinator is disposed.');
    }

    if (_started) return;
    _started = true;

    _eventSubscription = _dataSource.events.listen(
      _handleEvent,
      onError: _ignoreStreamError,
    );

    _readinessSubscription = _dataSource.readinessChanges.listen(
      _handleReadiness,
      onError: _ignoreStreamError,
    );

    final configuration = _dataSource.readyConfiguration;
    if (_dataSource.isReady && configuration != null) {
      _configure(configuration);
    }
  }

  void _handleEvent(AssistantIncomingEventModel event) {
    if (_disposed) return;

    switch (event) {
      case ConnectionReadyEventModel():
        _configure(event);

      case ConnectionPongEventModel():
        _handlePong();

      default:
        break;
    }
  }

  void _handleReadiness(bool isReady) {
    if (_disposed) return;

    if (!isReady) {
      _stopCycle(clearConfiguration: true);
    }
  }

  void _configure(ConnectionReadyEventModel ready) {
    if (_disposed || !_dataSource.isReady) return;
    _stopCycle(clearConfiguration: false);

    _heartbeatInterval = _seconds(ready.heartbeatIntervalSeconds);
    final remainingIdleTime = _seconds(
      ready.idleTimeoutSeconds - ready.heartbeatIntervalSeconds,
    );

    _pongTimeout = _heartbeatInterval! < remainingIdleTime
        ? _heartbeatInterval
        : remainingIdleTime;

    _scheduleHeartbeat();
  }

  void _scheduleHeartbeat() {
    _heartbeatTimer?.cancel();

    final interval = _heartbeatInterval;
    if (interval == null) return;
    final cycle = _cycle;
    _heartbeatTimer = _timerFactory(
      interval,
      () => unawaited(_sendPing(cycle)),
    );
  }

  Future<void> _sendPing(int cycle) async {
    if (!_isActiveCycle(cycle) || _awaitingPong) {
      return;
    }
    try {
      await _dataSource.sendPing(
        ConnectionPingEventModel(sentAt: _clock().toUtc()),
      );

      if (!_isActiveCycle(cycle)) return;

      final timeout = _pongTimeout;
      if (timeout == null) return;

      _awaitingPong = true;
      _pongTimer?.cancel();
      _pongTimer = _timerFactory(timeout, () => _handlePongTimeout(cycle));
    } on Object {
      final shouldInvalidateConnection = _isActiveCycle(cycle);
      _stopCycle(clearConfiguration: false);
      if (shouldInvalidateConnection) {
        _dataSource.reportHeartbeatTimeout();
      }
    }
  }

  void _handlePong() {
    if (_disposed || !_dataSource.isReady || !_awaitingPong) {
      return;
    }

    _pongTimer?.cancel();
    _pongTimer = null;
    _awaitingPong = false;

    _scheduleHeartbeat();
  }

  void _handlePongTimeout(int cycle) {
    if (!_isActiveCycle(cycle) || !_awaitingPong) {
      return;
    }

    _stopCycle(clearConfiguration: false);
    _dataSource.reportHeartbeatTimeout();
  }

  void _stopCycle({required bool clearConfiguration}) {
    _cycle++;

    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    _pongTimer?.cancel();
    _pongTimer = null;

    _awaitingPong = false;

    if (clearConfiguration) {
      _heartbeatInterval = null;
      _pongTimeout = null;
    }
  }

  void _ignoreStreamError(Object _, StackTrace _) {
    // Repository/session observes socket errors. Heartbeat only reacts to
    // readiness and successfully decoded protocol events.
  }

  static Duration _seconds(double value) {
    return Duration(
      microseconds: (value * Duration.microsecondsPerSecond).round(),
    );
  }

  @override
  Future<void> dispose() {
    final disposing = _disposeFuture;
    if (disposing != null) return disposing;

    _disposed = true;
    _stopCycle(clearConfiguration: true);
    final future = _dispose();
    _disposeFuture = future;
    return future;
  }

  Future<void> _dispose() {
    return Future.wait<void>([
      if (_eventSubscription != null) _eventSubscription!.cancel(),
      if (_readinessSubscription != null) _readinessSubscription!.cancel(),
    ]);
  }

  bool _isActiveCycle(int cycle) {
    return !_disposed && _dataSource.isReady && cycle == _cycle;
  }
}
