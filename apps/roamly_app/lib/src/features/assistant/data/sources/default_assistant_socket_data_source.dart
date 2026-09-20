import 'dart:async';
import 'dart:convert';

import 'package:roamly_app/src/features/assistant/data/models/assistant_incoming_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_ping_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_ready_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/serialization/assistant_event_decoder.dart';
import 'package:roamly_app/src/features/assistant/data/sources/assistant_socket_data_source.dart';
import 'package:roamly_networking/roamly_networking.dart';

import '../../domain/policies/assistant_policy.dart';

/// Assistant protocol adapter for one exclusively owned WebSocket manager.
///
/// Disposing this data source also disposes the injected [manager].
final class DefaultAssistantSocketDataSource
    implements AssistantSocketDataSource {
  final WebsocketManager _manager;
  final AssistantEventDecoder _decoder;
  final Duration readyTimeout;
  final int maximumIncomingMessageBytes;

  final StreamController<AssistantIncomingEventModel> _eventsController =
      StreamController<AssistantIncomingEventModel>.broadcast();
  final StreamController<bool> _readinessController =
      StreamController<bool>.broadcast();

  late final StreamSubscription<WebSocketMessage> _messageSubscription;
  late final StreamSubscription<WebSocketStatusSnapshot> _stateSubscription;

  Timer? _readyTimer;
  int? _readyGeneration;
  int? _maximumOutgoingMessageBytes;
  bool _isReady = false;
  bool _disposed = false;
  Future<void>? _disposeFuture;
  ConnectionReadyEventModel? _readyConfiguration;

  DefaultAssistantSocketDataSource({
    required WebsocketManager manager,
    AssistantEventDecoder decoder = const AssistantEventDecoder(),
    this.readyTimeout = AssistantPolicy.defaultReadyTimeout,
    this.maximumIncomingMessageBytes =
        AssistantPolicy.defaultMaximumIncomingMessageBytes,
  }) : _manager = manager,
       _decoder = decoder {
    if (readyTimeout <= Duration.zero) {
      throw ArgumentError.value(
        readyTimeout,
        'readyTimeout',
        'Must be greater than zero.',
      );
    }
    if (maximumIncomingMessageBytes <= 0 ||
        maximumIncomingMessageBytes >
            AssistantPolicy.maximumConfigurableIncomingMessageBytes) {
      throw ArgumentError.value(
        maximumIncomingMessageBytes,
        'maximumIncomingMessageBytes',
        'Must be between 1 byte and 4 MiB.',
      );
    }
    _messageSubscription = _manager.messages.listen(
      _handleMessage,
      onError: _handleStreamError,
    );
    _stateSubscription = _manager.socketStates.listen(
      _handleSocketState,
      onError: _handleStreamError,
    );
  }

  @override
  void connect() {
    _ensureActive();
    _manager.connect();
  }

  @override
  Future<void> disconnect() async {
    _ensureActive();
    _resetReadiness();
    await _manager.disconnect();
  }

  @override
  Future<void> dispose() {
    final disposing = _disposeFuture;
    if (disposing != null) return disposing;

    _resetReadiness();
    _disposed = true;
    final future = _dispose();
    _disposeFuture = future;
    return future;
  }

  @override
  Stream<AssistantIncomingEventModel> get events => _eventsController.stream;

  @override
  bool get isReady => _isReady;

  @override
  Stream<bool> get readinessChanges => _readinessController.stream;

  @override
  Future<void> sendPing(ConnectionPingEventModel ping) {
    return _send(ping.toJson());
  }

  @override
  Future<void> sendTravelRequest(TravelRequestEventModel request) {
    return _send(request.toJson());
  }

  @override
  Stream<WebSocketStatusSnapshot> get socketStates => _manager.socketStates;

  @override
  WebSocketStatusSnapshot get status => _manager.status;

  Future<void> _dispose() async {
    try {
      await Future.wait<void>([
        _manager.dispose(),
        _stateSubscription.cancel(),
        _messageSubscription.cancel(),
      ]);
    } finally {
      // A paused external listener must not hold resource disposal open.
      unawaited(_eventsController.close());
      unawaited(_readinessController.close());
    }
  }

  void _handleStreamError(Object error, StackTrace stackTrace) {
    if (!_disposed) {
      _eventsController.addError(_safeError(error), stackTrace);
    }
  }

  void _ensureActive() {
    if (_disposed) {
      throw StateError('AssistantSocketDataSource is disposed.');
    }
  }

  void _handleMessage(WebSocketMessage frame) {
    if (_disposed || !_manager.isCurrent(frame.generation)) return;

    if (utf8.encode(frame.text).length > maximumIncomingMessageBytes) {
      final failure = WebSocketFailure(
        kind: WebSocketFailureKind.messageTooLarge,
      );
      _eventsController.addError(failure);
      _manager.reportFailure(frame.generation, failure);
      return;
    }

    try {
      final message = _decoder.decode(frame.text);
      if (!_manager.isCurrent(frame.generation)) return;

      if (message is ConnectionReadyEventModel) {
        if (_readyGeneration != null) {
          throw const FormatException('Duplicate Assistant ready event.');
        }
        _manager.markReady(frame.generation);
        _readyTimer?.cancel();
        _readyGeneration = frame.generation;
        _maximumOutgoingMessageBytes = message.maxMessageBytes;
        _readyConfiguration = message;
        _setReady(true);
      } else if (_readyGeneration != frame.generation) {
        throw const FormatException(
          'Assistant event received before protocol readiness.',
        );
      }

      _eventsController.add(message);
    } on FormatException catch (error, stackTrace) {
      _eventsController.addError(_safeError(error), stackTrace);
    } on Object catch (error, stackTrace) {
      final failure = error is WebSocketFailure
          ? error
          : WebSocketFailure(kind: WebSocketFailureKind.unknown);
      _eventsController.addError(failure, stackTrace);
      _manager.reportFailure(frame.generation, failure);
    }
  }

  void _handleSocketState(WebSocketStatusSnapshot snapshot) {
    if (_disposed) return;

    switch (snapshot.state) {
      case WebSocketConnectionState.connected:
        if (_readyGeneration != snapshot.generation) {
          _resetReadiness();
          _startReadyTimer(snapshot.generation);
        }

      case WebSocketConnectionState.connecting:
      case WebSocketConnectionState.disconnected:
      case WebSocketConnectionState.disconnecting:
      case WebSocketConnectionState.disposed:
      case WebSocketConnectionState.reconnecting:
        _resetReadiness();
    }
  }

  void _startReadyTimer(int generation) {
    _readyTimer?.cancel();
    _readyTimer = Timer(readyTimeout, () {
      if (_disposed ||
          _readyGeneration == generation ||
          !_manager.isCurrent(generation)) {
        return;
      }
      final failure = WebSocketFailure(kind: WebSocketFailureKind.timeout);
      _eventsController.addError(failure);
      _manager.reportFailure(generation, failure);
    });
  }

  void _resetReadiness() {
    _readyTimer?.cancel();
    _readyTimer = null;
    _readyGeneration = null;
    _maximumOutgoingMessageBytes = null;
    _readyConfiguration = null;
    _setReady(false);
  }

  void _setReady(bool value) {
    if (_isReady == value) return;
    _isReady = value;
    if (!_readinessController.isClosed) {
      _readinessController.add(value);
    }
  }

  Future<void> _send(Map<String, Object?> json) async {
    _ensureActive();
    final generation = _readyGeneration;
    final maximumBytes = _maximumOutgoingMessageBytes;
    if (generation == null ||
        maximumBytes == null ||
        !_manager.isCurrent(generation)) {
      throw WebSocketFailure(kind: WebSocketFailureKind.connection);
    }

    final text = jsonEncode(json);
    if (utf8.encode(text).length > maximumBytes) {
      throw WebSocketFailure(kind: WebSocketFailureKind.messageTooLarge);
    }

    await _manager.send(text, generation: generation);
  }

  static Object _safeError(Object error) {
    return switch (error) {
      WebSocketFailure() => error,
      FormatException() => const FormatException('Invalid Assistant event.'),
      _ => WebSocketFailure(kind: WebSocketFailureKind.unknown),
    };
  }

  @override
  void reportHeartbeatTimeout() {
    _ensureActive();

    final generation = _readyGeneration;
    if (generation == null || !_manager.isCurrent(generation)) {
      return;
    }
    _resetReadiness();
    _manager.reportFailure(
      generation,
      WebSocketFailure(kind: WebSocketFailureKind.timeout),
    );
  }

  @override
  ConnectionReadyEventModel? get readyConfiguration => _readyConfiguration;
}
