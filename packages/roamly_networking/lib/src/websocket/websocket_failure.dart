import 'package:roamly_core/roamly_core.dart';


enum WebSocketFailureKind {
  connection,
  timeout,
  unauthorized,
  forbidden,
  protocol,
  messageTooLarge,
  retriesExhausted,
  unknown,
}

final class WebSocketFailure extends AppFailure {
   WebSocketFailure({required this.kind, this.closeCode})
    : super(
        code: switch (kind) {
          WebSocketFailureKind.connection => 'websocket_connection',
          WebSocketFailureKind.timeout => 'websocket_timeout',
          WebSocketFailureKind.unauthorized => 'websocket_unauthorized',
          WebSocketFailureKind.forbidden => 'websocket_forbidden',
          WebSocketFailureKind.protocol => 'websocket_protocol',
          WebSocketFailureKind.messageTooLarge => 'websocket_message_too_large',
          WebSocketFailureKind.retriesExhausted =>
            'websocket_retries_exhausted',
          WebSocketFailureKind.unknown => 'websocket_unknown',
        },
        isRetryable:
            kind == WebSocketFailureKind.connection ||
            kind == WebSocketFailureKind.timeout,
      );

  final WebSocketFailureKind kind;
  final int? closeCode;
}
