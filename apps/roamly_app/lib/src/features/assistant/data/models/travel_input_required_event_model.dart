import '../serialization/assistant_event_reader.dart';
import 'assistant_incoming_event_model.dart';
import 'travel_clarification_model.dart';

final class TravelInputRequiredEventModel
    implements AssistantIncomingEventModel {
  const TravelInputRequiredEventModel._({
    required this.sentAt,
    required this.clientMessageId,
    required this.conversationId,
    required this.assistantMessageId,
    required this.content,
    required this.isDuplicate,
    required this.clarification,
  });

  @override
  final DateTime sentAt;
  final String clientMessageId;
  final String conversationId;
  final String assistantMessageId;
  final String content;
  final bool isDuplicate;
  final TravelClarificationModel clarification;

  factory TravelInputRequiredEventModel.fromJson(Map<String, Object?> json) {
    final event = AssistantEventReader.fromJson(
      json,
      expectedType: 'travel.input.required',
    );
    final payload = event.payload;
    final content = payload.string('content', minLength: 1);
    if (content.trim().isEmpty) {
      throw const FormatException(
        'Assistant clarification content must not be blank.',
      );
    }

    return TravelInputRequiredEventModel._(
      sentAt: event.sentAt,
      clientMessageId: event.uuid('client_message_id'),
      conversationId: event.uuid('conversation_id'),
      assistantMessageId: event.uuid('assistant_message_id'),
      content: content,
      isDuplicate: payload.boolean('is_duplicate'),
      clarification: TravelClarificationModel.fromJson(
        payload.object('clarification'),
      ),
    );
  }
}
