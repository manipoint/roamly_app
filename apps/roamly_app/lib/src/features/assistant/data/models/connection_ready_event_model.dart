import '../policies/assistant_data_policy.dart';
import '../serialization/assistant_event_reader.dart';
import 'assistant_incoming_event_model.dart';

final class ConnectionReadyEventModel implements AssistantIncomingEventModel {
  @override
  final DateTime sentAt;
  final String connectionId;
  final double heartbeatIntervalSeconds;
  final double idleTimeoutSeconds;
  final int maxMessageBytes;

  const ConnectionReadyEventModel._({
    required this.sentAt,
    required this.connectionId,
    required this.heartbeatIntervalSeconds,
    required this.idleTimeoutSeconds,
    required this.maxMessageBytes,
  });

  factory ConnectionReadyEventModel.fromJson(Map<String, Object?> json) {
    final event = AssistantEventReader.fromJson(
      json,
      expectedType: 'connection.ready',
    );
    final payload = event.payload;
    final connectionId = event.uuid('connection_id');
    final heartbeatIntervalSeconds = payload.number(
      'heartbeat_interval_seconds',
      max: AssistantDataPolicy.maximumHeartbeatIntervalSeconds,
    );
    final idleTimeoutSeconds = payload.number(
      'idle_timeout_seconds',
      max: AssistantDataPolicy.maximumIdleTimeoutSeconds,
    );
    if (heartbeatIntervalSeconds <= 0 ||
        idleTimeoutSeconds <= 0 ||
        heartbeatIntervalSeconds >= idleTimeoutSeconds) {
      throw const FormatException('Invalid WebSocket heartbeat configuration.');
    }
    final maxMessageBytes = payload.integer(
      'max_message_bytes',
      min: 1,
      max: AssistantDataPolicy.maximumNegotiatedOutgoingMessageBytes,
    );
    return ConnectionReadyEventModel._(
      sentAt: event.sentAt,
      connectionId: connectionId,
      heartbeatIntervalSeconds: heartbeatIntervalSeconds,
      idleTimeoutSeconds: idleTimeoutSeconds,
      maxMessageBytes: maxMessageBytes,
    );
  }
}
