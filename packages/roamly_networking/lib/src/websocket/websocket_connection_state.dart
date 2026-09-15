/// Lifecycle of the underlying WebSocket connection.
///
/// Application-protocol readiness is tracked by the feature adapter.
enum WebSocketConnectionState {
  /// No connection and no automatic connection attempt scheduled.
  disconnected,

  /// Initial or manually requested connection attempt is running.
  connecting,

  /// Socket is open; application handshake may still be pending.
  connected,

  /// Automatic retry is scheduled or currently running.
  reconnecting,

  /// Connection is closing and automatic retries are disabled.
  disconnecting,

  /// Manager has released its resources and cannot be reused.
  disposed,
}
