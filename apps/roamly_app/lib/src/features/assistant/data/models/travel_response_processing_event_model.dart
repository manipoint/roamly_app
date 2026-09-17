import '../serialization/assistant_event_reader.dart';
import 'assistant_incoming_event_model.dart';

final class TravelResponseProcessingEventModel
    implements AssistantIncomingEventModel {
  const TravelResponseProcessingEventModel._({
    required this.sentAt,
    required this.clientMessageId,
    required this.conversationId,
  });
  @override
  final DateTime sentAt;
  final String clientMessageId;
  final String conversationId;

  factory TravelResponseProcessingEventModel.fromJson(
    Map<String, Object?> json,
  ) {
    final event = AssistantEventReader.fromJson(
      json,
      expectedType: 'travel.response.processing',
    );
    return TravelResponseProcessingEventModel._(
      sentAt: event.sentAt,
      clientMessageId: event.uuid('client_message_id'),
      conversationId: event.uuid('conversation_id'),
    );
  }
}
