import 'package:roamly_app/src/features/assistant/data/models/assistant_incoming_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/services/assistant_heartbeat_coordinator.dart';
import 'package:roamly_app/src/features/assistant/data/services/assistant_realtime_session.dart';

import '../sources/assistant_socket_data_source.dart';

/// Owns the Assistant socket data source and heartbeat coordinator.
///
/// Disposal order is important: heartbeat stops before the socket data source
/// is disposed, preventing late timer callbacks from using a closed socket.
final class DefaultAssistantRealtimeSession
    implements AssistantRealtimeSession {
  final AssistantSocketDataSource _socketDataSource;
  final AssistantHeartbeatCoordinator _heartbeatCoordinator;
  bool _heartbeatStarted = false;
  bool _disposed = false;
  Future<void>? _disposeFuture;

  DefaultAssistantRealtimeSession({
    required AssistantSocketDataSource socketDataSource,
    required AssistantHeartbeatCoordinator heartbeatCoordinator,
  }) : _socketDataSource = socketDataSource,
       _heartbeatCoordinator = heartbeatCoordinator;

  @override
  void connect() {
    _ensureActive();
    if (!_heartbeatStarted) {
      _heartbeatCoordinator.start();
      _heartbeatStarted = true;
    }
    _socketDataSource.connect();
  }

  @override
  Future<void> sendTravelRequest(TravelRequestEventModel request) {
    _ensureActive();
    return _socketDataSource.sendTravelRequest(request);
  }

  @override
  Future<void> disconnect() {
    _ensureActive();
    return _socketDataSource.disconnect();
  }

  @override
  Future<void> dispose() {
    final disposing = _disposeFuture;
    if (disposing != null) return disposing;
    _disposed = true;
    final future = _dispose();
    _disposeFuture = future;
    return future;
  }

  @override
  Stream<AssistantIncomingEventModel> get events => _socketDataSource.events;

  @override
  bool get isReady => _socketDataSource.isReady;

  @override
  Stream<bool> get readinessChanges => _socketDataSource.readinessChanges;

  void _ensureActive() {
    if (_disposed) {
      throw StateError('AssistantRealtimeSession is disposed.');
    }
  }

  Future<void> _dispose() async {
    try {
      await _heartbeatCoordinator.dispose();
    } finally {
      await _socketDataSource.dispose();
    }
  }
}
