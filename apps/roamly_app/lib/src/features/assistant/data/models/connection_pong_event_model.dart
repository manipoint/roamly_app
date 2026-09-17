import '../serialization/assistant_event_reader.dart';
import 'assistant_incoming_event_model.dart';

final class ConnectionPongEventModel implements AssistantIncomingEventModel {
  const ConnectionPongEventModel._({required this.sentAt});

  @override
  final DateTime sentAt;

  factory ConnectionPongEventModel.fromJson(Map<String, Object?> json) {
    final event = AssistantEventReader.fromJson(
      json,
      expectedType: 'connection.pong',
    );
    return ConnectionPongEventModel._(sentAt: event.sentAt);
  }
}
