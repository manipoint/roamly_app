/// Creates an independent socket connection for each attempt.
///
/// Implementations must enforce [connectTimeout] and release resources
/// if the connection attempt fails or times out.
abstract interface class WebsocketTransport {
  Future<WebSocketConnection> connect({
    required Uri uri,
    required Duration connectTimeout,
    Map<String, String> headers = const {},
  });
}

/// Owns one established socket connection.
///
/// Instances must never be reused for reconnection.
abstract interface class WebSocketConnection {
  /// Incoming text frames.
  ///
  /// Supports one listener. Transport errors are emitted through this
  /// stream, which closes when the connection ends.
  ///
  /// Implementations must reject unsupported binary frames.
  Stream<String> get message;

  /// Completes when the connection closes.
  ///
  /// Transport errors are reported through [messages]; this future
  /// completes normally with the available close information.
  Future<WebSocketCloseInfo> get closed;

  /// Submits a text frame to the local socket.
  ///
  /// Completion does not mean the server accepted or persisted it.
  /// Throws when the connection cannot accept the frame.
  Future<void> send(String message);

  /// Closes this connection and releases its resources.
  ///
  /// Must be idempotent and finish within an implementation-defined
  /// bounded timeout, including when the peer does not respond.
  Future<void> close({int code = 1000, String? reason});
}

/// Describes how an established connection ended.
final class WebSocketCloseInfo {
  const WebSocketCloseInfo({this.code, this.reason});

  /// Null when no close code was received.
  final int? code;

  /// Untrusted peer-provided text; do not display or log directly.
  final String? reason;
}
