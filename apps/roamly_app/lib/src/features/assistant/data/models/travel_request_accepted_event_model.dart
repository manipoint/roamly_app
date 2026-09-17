import '../serialization/assistant_event_reader.dart';
import 'assistant_incoming_event_model.dart';

final class TravelRequestAcceptedEventModel
    implements AssistantIncomingEventModel {
  const TravelRequestAcceptedEventModel._({
    required this.sentAt,
    required this.clientMessageId,
    required this.conversationId,
  });

  @override
  final DateTime sentAt;
  final String clientMessageId;
  final String conversationId;

  factory TravelRequestAcceptedEventModel.fromJson(Map<String, Object?> json) {
    final event = AssistantEventReader.fromJson(
      json,
      expectedType: 'travel.request.accepted',
    );
    return TravelRequestAcceptedEventModel._(
      sentAt: event.sentAt,
      clientMessageId: event.uuid('client_message_id'),
      conversationId: event.uuid('conversation_id'),
    );
  }
}
