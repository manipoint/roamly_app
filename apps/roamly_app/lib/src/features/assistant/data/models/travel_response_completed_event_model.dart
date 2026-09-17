import '../serialization/assistant_event_reader.dart';
import 'assistant_incoming_event_model.dart';

final class TravelResponseCompletedEventModel
    implements AssistantIncomingEventModel {
  @override
  final DateTime sentAt;
  final String clientMessageId;
  final String conversationId;
  final String assistantMessageId;
  final String content;
  final bool isDuplicate;
  final String? itineraryId;

  const TravelResponseCompletedEventModel._({
    required this.sentAt,
    required this.clientMessageId,
    required this.conversationId,
    required this.assistantMessageId,
    required this.content,
    required this.isDuplicate,
    required this.itineraryId,
  });
  factory TravelResponseCompletedEventModel.fromJson(
    Map<String, Object?> json,
  ) {
    final event = AssistantEventReader.fromJson(
      json,
      expectedType: 'travel.response.completed',
    );
    final payload = event.payload;
    final clientMessageId = event.uuid('client_message_id');
    final conversationId = event.uuid('conversation_id');
    final assistantMessageId = event.uuid('assistant_message_id');
    final content = payload.string('content', minLength: 1);
    if (content.trim().isEmpty) {
      throw const FormatException(
        'Assistant response content must not be blank.',
      );
    }
    final isDuplicate = payload.boolean('is_duplicate');
    final itineraryId = payload.nullable<String>(
      'itinerary_id',
      () => event.uuid('itinerary_id'),
      allowMissing: true,
    );
    return TravelResponseCompletedEventModel._(
      sentAt: event.sentAt,
      clientMessageId: clientMessageId,
      conversationId: conversationId,
      assistantMessageId: assistantMessageId,
      content: content,
      isDuplicate: isDuplicate,
      itineraryId: itineraryId,
    );
  }
}
