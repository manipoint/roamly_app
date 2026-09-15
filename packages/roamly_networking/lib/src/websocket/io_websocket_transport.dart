import 'dart:async';
import 'dart:io';

import 'websocket_failure.dart';
import 'websocket_transport.dart';

/// Native-platform WebSocket transport.
///
/// Reconnection and authentication refresh belong to higher layers.
final class IoWebSocketTransport implements WebsocketTransport {
  const IoWebSocketTransport();

  @override
  Future<WebSocketConnection> connect({
    required Uri uri,
    required Duration connectTimeout,
    Map<String, String> headers = const {},
  }) async {
    if ((uri.scheme != 'ws' && uri.scheme != 'wss') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment) {
      throw ArgumentError('Invalid WebSocket endpoint.');
    }

    if (connectTimeout <= Duration.zero) {
      throw ArgumentError('connectTimeout must be positive.');
    }

    final client = HttpClient()..connectionTimeout = connectTimeout;

    var abandoned = false;

    Future<WebSocket> openSocket() async {
      final socket = await WebSocket.connect(
        uri.toString(),
        headers: Map<String, String>.of(headers),
        customClient: client,
        compression: CompressionOptions.compressionOff,
      );
      if (abandoned) {
        await socket.close().timeout(const Duration(seconds: 6));
        throw TimeoutException('Connection attempt expired.');
      }

      return socket;
    }

    try {
      final socket = await openSocket().timeout(
        connectTimeout,
        onTimeout: () {
          abandoned = true;
          client.close(force: true);
          throw TimeoutException('Connection attempt expired.');
        },
      );

      return _IoWebSocketConnection(socket);
    } on Object catch (error) {
      abandoned = true;
      throw _mapFailure(error);
    } finally {
      // An upgraded socket is detached from the HTTP client.
      client.close(force: true);
    }
  }
}

final class _IoWebSocketConnection implements WebSocketConnection {
  _IoWebSocketConnection(this._socket) {
    _messages.onCancel = close;

    _subscription = _socket.listen(
      _onData,
      onError: (Object error, StackTrace _) {
        if (_finished) return;

        _messages.addError(_mapFailure(error));
        unawaited(close());
      },
      onDone: _finish,
      cancelOnError: false,
    );
  }

  static const _closeTimeout = Duration(seconds: 6);

  final WebSocket _socket;
  final StreamController<String> _messages = StreamController<String>();
  final Completer<WebSocketCloseInfo> _closed = Completer<WebSocketCloseInfo>();

  late final StreamSubscription<dynamic> _subscription;

  Future<void>? _closing;
  bool _finished = false;

  @override
  Stream<String> get message => _messages.stream;

  @override
  Future<WebSocketCloseInfo> get closed => _closed.future;

  void _onData(dynamic data) {
    if (_finished || _closing != null) return;

    if (data is String) {
      _messages.add(data);
      return;
    }

    _messages.addError(WebSocketFailure(kind: WebSocketFailureKind.protocol));

    unawaited(
      close(
        code: WebSocketStatus.unsupportedData,
        reason: 'Text frames required',
      ),
    );
  }

  @override
  Future<void> send(String message) async {
    if (_finished || _closing != null || _socket.readyState != WebSocket.open) {
      throw WebSocketFailure(kind: WebSocketFailureKind.connection);
    }

    try {
      _socket.add(message);
    } on Object catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> close({
    int code = WebSocketStatus.normalClosure,
    String? reason,
  }) {
    if (_finished) return Future<void>.value();

    return _closing ??= _close(code, reason);
  }

  Future<void> _close(int code, String? reason) async {
    try {
      await (() async {
        await _socket.close(code, reason);
        await _closed.future;
      })().timeout(_closeTimeout);
    } on Object catch (error) {
      if (!_finished) {
        _messages.addError(_mapFailure(error));
      }
    } finally {
      _finish();
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;

    _closed.complete(
      WebSocketCloseInfo(code: _socket.closeCode, reason: _socket.closeReason),
    );

    unawaited(_messages.close());
    unawaited(_cancelSubscription());
  }

  Future<void> _cancelSubscription() async {
    try {
      await _subscription.cancel().timeout(_closeTimeout);
    } on Object {
      // Connection has already reached its terminal state.
      // Never expose raw socket errors during cleanup.
    }
  }
}

WebSocketFailure _mapFailure(Object error) {
  if (error is WebSocketFailure) return error;

  final kind = switch (error) {
    TimeoutException() => WebSocketFailureKind.timeout,
    HandshakeException() => WebSocketFailureKind.protocol,
    SocketException() => WebSocketFailureKind.connection,
    WebSocketException() => WebSocketFailureKind.protocol,
    _ => WebSocketFailureKind.unknown,
  };

  return WebSocketFailure(kind: kind);
}
