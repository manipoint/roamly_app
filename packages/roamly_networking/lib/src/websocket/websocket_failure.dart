import 'package:roamly_core/roamly_core.dart';

enum WebSocketFailureKind {
  connection,
  timeout,
  unauthorized,
  forbidden,
  rateLimited,
  protocol,
  messageTooLarge,
  retriesExhausted,
  unknown,
}

final class WebSocketFailure extends AppFailure {
  WebSocketFailure({required this.kind, this.closeCode, this.httpStatusCode})
    : super(
        code: switch (kind) {
          WebSocketFailureKind.connection => 'websocket_connection',
          WebSocketFailureKind.timeout => 'websocket_timeout',
          WebSocketFailureKind.unauthorized => 'websocket_unauthorized',
          WebSocketFailureKind.forbidden => 'websocket_forbidden',
          WebSocketFailureKind.rateLimited => 'websocket_rate_limited',
          WebSocketFailureKind.protocol => 'websocket_protocol',
          WebSocketFailureKind.messageTooLarge => 'websocket_message_too_large',
          WebSocketFailureKind.retriesExhausted =>
            'websocket_retries_exhausted',
          WebSocketFailureKind.unknown => 'websocket_unknown',
        },
        isRetryable:
            kind == WebSocketFailureKind.connection ||
            kind == WebSocketFailureKind.timeout ||
            kind == WebSocketFailureKind.rateLimited,
      );

  final WebSocketFailureKind kind;
  final int? closeCode;

  /// HTTP handshake response status, separate from a WebSocket close code.
  ///
  /// Retryable failures require bounded backoff; they must not trigger an
  /// immediate retry or automatic replay of application messages.
  final int? httpStatusCode;
}
