import 'dart:async';

import 'package:roamly_logging/roamly_logging.dart';

import 'reconnect_policy.dart';
import 'websocket_connection_state.dart';
import 'websocket_failure.dart';
import 'websocket_transport.dart';

typedef WebSocketCloseClassifier =
    WebSocketFailure Function(WebSocketCloseInfo);
typedef WebSocketHeadersProvider = Future<Map<String, String>> Function();

final class WebSocketStatusSnapshot {
  final WebSocketConnectionState state;
  final int generation;
  final int retryAttempt;
  final Duration? retryDelay;
  final WebSocketFailure? failure;

  WebSocketStatusSnapshot({
    required this.state,
    required this.generation,
    this.retryAttempt = 0,
    this.retryDelay,
    this.failure,
  });
}

final class WebSocketMessage {
  final int generation;
  final String text;

  WebSocketMessage({required this.generation, required this.text});
}

final class WebsocketManager {
  WebsocketManager({
    required WebsocketTransport transport,
    required Uri uri,
    required WebSocketHeadersProvider headersProvider,
    ReconnectPolicy? reconnectPolicy,
    WebSocketCloseClassifier? classifyClose,
    RoamlyLogger? logger,
    this.connectTimeout = const Duration(seconds: 15),
    this.stableConnectionDuration = const Duration(seconds: 10),
  }) : _transport = transport,
       _uri = uri,
       _headersProvider = headersProvider,
       _policy = reconnectPolicy ?? ReconnectPolicy(),
       _closeClassifier = classifyClose ?? defaultCloseFailure,
       _logger =
           (logger ??
                   RoamlyLogger(
                     name: 'roamly.networking',
                     sink: const NoopLogSink(),
                   ))
               .child('websocket') {
    if ((uri.scheme != 'ws' && uri.scheme != 'wss') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment) {
      throw ArgumentError('Invalid WebSocket endpoint.');
    }
    if (connectTimeout <= Duration.zero ||
        stableConnectionDuration <= Duration.zero) {
      throw ArgumentError('Timeout and stable duration must be positive.');
    }
  }
  final WebsocketTransport _transport;
  final Uri _uri;
  final WebSocketHeadersProvider _headersProvider;
  final ReconnectPolicy _policy;
  final WebSocketCloseClassifier _closeClassifier;
  final RoamlyLogger _logger;
  final Duration connectTimeout;
  final Duration stableConnectionDuration;

  final _socketStates = StreamController<WebSocketStatusSnapshot>.broadcast();
  final _messages = StreamController<WebSocketMessage>.broadcast();
  WebSocketStatusSnapshot _status = WebSocketStatusSnapshot(
    state: WebSocketConnectionState.disconnected,
    generation: 0,
  );
  Completer<void>? _stop;
  Future<void>? _running;
  Future<void>? _disposing;
  WebSocketConnection? _connection;
  Completer<WebSocketFailure>? _connectionEnd;
  Timer? _stableTimer;
  bool _ready = false;
  bool _disposed = false;
  int _generation = 0;
  int _retryAttempt = 0;

  WebSocketStatusSnapshot get status => _status;
  Stream<WebSocketStatusSnapshot> get socketStates => _socketStates.stream;
  Stream<WebSocketMessage> get messages => _messages.stream;

  void connect() {
    if (_disposed) throw StateError('WebSocketManager is disposed.');
    if (_running != null) {
      if (_stop!.isCompleted) {
        throw StateError('Await disconnect before reconnecting.');
      }
      return;
    }
    if (!_messages.hasListener) {
      throw StateError('Subscribe to messages before connecting.');
    }
    _retryAttempt = 0;
    final stop = _stop = Completer<void>();
    _running = _run(stop).whenComplete(() {
      if (identical(_stop, stop)) _running = null;
    });
  }

  void markReady(int generation) {
    if (!isCurrent(generation) || _ready) return;
    _ready = true;
    _stableTimer = Timer(stableConnectionDuration, () {
      if (isCurrent(generation)) _retryAttempt = 0;
    });
  }

  bool isCurrent(int generation) {
    return !_disposed &&
        _stop?.isCompleted == false &&
        _connection != null &&
        _connectionEnd?.isCompleted == false &&
        generation == _generation;
  }

  void reportFailure(int generation, WebSocketFailure failure) {
    if (isCurrent(generation)) _connectionEnd!.complete(failure);
  }

  Future<void> send(String text, {required int generation}) async {
    if (!isCurrent(generation)) {
      throw WebSocketFailure(kind: WebSocketFailureKind.connection);
    }
    try {
      await _connection!.send(text);
    } on Object catch (e) {
      final failure = _safeFailure(e);
      reportFailure(generation, failure);
      throw failure;
    }
  }

  Future<void> disconnect() async {
    final running = _running;
    if (running == null) return;
    if (!_stop!.isCompleted) {
      _stop!.complete();
      _stableTimer?.cancel();
      _emit(WebSocketConnectionState.disconnecting);
    }
    await running;
  }

  Future<void> dispose() => _disposing ??= _dispose();
  Future<void> _dispose() async {
    _disposed = true;
    await disconnect();
    _emit(WebSocketConnectionState.disposed);
    unawaited(_socketStates.close());
    unawaited(_messages.close());
  }

  Future<void> _run(Completer<void> stop) async {
    while (!stop.isCompleted) {
      final generation = ++_generation;
      WebSocketConnection? socket;
      StreamSubscription<String>? subscription;
      WebSocketFailure? failure;
      _ready = false;
      _emit(
        _retryAttempt == 0
            ? WebSocketConnectionState.connecting
            : WebSocketConnectionState.reconnecting,
      );
      try {
        final headers = await _headersProvider().timeout(connectTimeout);
        if (stop.isCompleted) break;
        socket = await _transport.connect(
          uri: _uri,
          connectTimeout: connectTimeout,
          headers: headers,
        );
        if (stop.isCompleted) break;
        _connection = socket;
        final end = _connectionEnd = Completer<WebSocketFailure>();
        subscription = socket.message.listen(
          (text) {
            if (isCurrent(generation)) {
              _messages.add(
                WebSocketMessage(generation: generation, text: text),
              );
            }
          },
          onError: (Object error, StackTrace _) {
            reportFailure(generation, _safeFailure(error));
          },
        );

        unawaited(
          socket.closed.then(
            (info) {
              if (!isCurrent(generation)) return;
              _log(
                LogLevel.info,
                'WebSocket connection closed',
                closeCode: info.code,
              );
              try {
                reportFailure(generation, _closeClassifier(info));
              } on Object catch (e) {
                reportFailure(generation, _safeFailure(e));
              }
            },
            onError: (Object e, StackTrace _) =>
                reportFailure(generation, _safeFailure(e)),
          ),
        );

        _emit(WebSocketConnectionState.connected);
        failure = await Future.any<WebSocketFailure?>([
          end.future,
          stop.future.then<WebSocketFailure?>((_) => null),
        ]);
      } on Object catch (e) {
        failure = _safeFailure(e);
      } finally {
        _stableTimer?.cancel();
        _stableTimer = null;
        _connection = null;
        _connectionEnd = null;
        if (socket != null) {
          try {
            await Future.wait([
              socket.close(),
              if (subscription != null) subscription.cancel(),
            ]).timeout(const Duration(seconds: 7));
          } on Object catch (e) {
            _log(
              LogLevel.error,
              'WebSocket cleanup failed',
              failure: _safeFailure(e),
            );
            failure ??= _safeFailure(e);
          }
        }
      }
      if (stop.isCompleted) break;
      failure ??= WebSocketFailure(kind: WebSocketFailureKind.connection);
      if (!failure.isRetryable) {
        _running = null;
        _emit(WebSocketConnectionState.disconnected, failure: failure);
        return;
      }
      final delay = _policy.delayForRetry(++_retryAttempt);
      if (delay == null) {
        _running = null;
        _emit(
          WebSocketConnectionState.disconnected,
          failure: WebSocketFailure(
            kind: WebSocketFailureKind.retriesExhausted,
          ),
        );
        return;
      }
      _emit(
        WebSocketConnectionState.reconnecting,
        failure: failure,
        retryDelay: delay,
      );
      final elapsed = Completer<void>();
      final timer = Timer(delay, elapsed.complete);
      await Future.any([elapsed.future, stop.future]);
      timer.cancel();
    }
    _emit(WebSocketConnectionState.disconnected);
  }

  void _emit(
    WebSocketConnectionState webSocketConnectionState, {
    WebSocketFailure? failure,
    Duration? retryDelay,
  }) {
    _status = WebSocketStatusSnapshot(
      state: webSocketConnectionState,
      generation: _generation,
      retryAttempt: _retryAttempt,
      failure: failure,
      retryDelay: retryDelay,
    );
    _socketStates.add(_status);
    final message = switch (webSocketConnectionState) {
      WebSocketConnectionState.connecting => 'WebSocket connection attempt',
      WebSocketConnectionState.connected => 'WebSocket connected',
      WebSocketConnectionState.reconnecting =>
        retryDelay == null
            ? 'WebSocket connection attempt'
            : 'WebSocket retry scheduled',
      WebSocketConnectionState.disconnecting =>
        'WebSocket disconnect requested',
      WebSocketConnectionState.disconnected => 'WebSocket disconnected',
      WebSocketConnectionState.disposed => 'WebSocket manager disposed',
    };
    final level = switch (failure?.kind) {
      WebSocketFailureKind.retriesExhausted ||
      WebSocketFailureKind.unknown => LogLevel.error,
      null => LogLevel.info,
      _ => LogLevel.warning,
    };
    _log(level, message, failure: failure, retryDelay: retryDelay);
  }

  /// Allowlisted metadata only. Never pass URI, credentials, message text,
  /// peer reason, raw exceptions or stack traces to the logger.
  void _log(
    LogLevel level,
    String message, {
    WebSocketFailure? failure,
    Duration? retryDelay,
    int? closeCode,
  }) {
    try {
      _logger.log(
        level,
        message,
        fields: {
          'generation': _generation,
          'retry_attempt': _retryAttempt,
          if (retryDelay != null) 'retry_delay_ms': retryDelay.inMilliseconds,
          if (failure != null) 'failure_kind': failure.kind.name,
          if (failure?.httpStatusCode != null)
            'http_status_code': failure!.httpStatusCode,
          if (closeCode != null || failure?.closeCode != null)
            'close_code': closeCode ?? failure!.closeCode,
        },
      );
    } on Object {
      // Logging failures must not interrupt connection or cleanup behavior.
    }
  }

  static WebSocketFailure _safeFailure(Object error) {
    return switch (error) {
      WebSocketFailure() => error,
      TimeoutException() => WebSocketFailure(
        kind: WebSocketFailureKind.timeout,
      ),
      _ => WebSocketFailure(kind: WebSocketFailureKind.unknown),
    };
  }

  static WebSocketFailure defaultCloseFailure(WebSocketCloseInfo info) {
    final code = info.code;
    final kind = switch (code) {
      1003 || 1007 || 1008 => WebSocketFailureKind.protocol,
      1009 => WebSocketFailureKind.messageTooLarge,
      null ||
      1000 ||
      1001 ||
      1005 ||
      1006 ||
      1011 ||
      1012 ||
      1013 => WebSocketFailureKind.connection,
      _ => WebSocketFailureKind.protocol,
    };
    return WebSocketFailure(kind: kind, closeCode: code);
  }
}
