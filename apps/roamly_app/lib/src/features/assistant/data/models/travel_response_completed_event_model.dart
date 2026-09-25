import 'package:roamly_app/src/features/assistant/data/models/assistant_rich_content_model.dart';

import 'package:roamly_networking/roamly_networking.dart';
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
  final AssistantRichContentModel? richContent;
  final bool hasInvalidRichContent;

  const TravelResponseCompletedEventModel._({
    required this.sentAt,
    required this.clientMessageId,
    required this.conversationId,
    required this.assistantMessageId,
    required this.content,
    required this.isDuplicate,
    required this.itineraryId,
    required this.richContent,
    required this.hasInvalidRichContent,
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
    final parsedRichContent = _readRichContent(payload);
    return TravelResponseCompletedEventModel._(
      sentAt: event.sentAt,
      clientMessageId: clientMessageId,
      conversationId: conversationId,
      assistantMessageId: assistantMessageId,
      content: content,
      isDuplicate: isDuplicate,
      itineraryId: itineraryId,
      richContent: parsedRichContent.content,
      hasInvalidRichContent: parsedRichContent.isInvalid,
    );
  }

  static ({AssistantRichContentModel? content, bool isInvalid})
  _readRichContent(JsonReader payload) {
    try {
      final content = payload.nullable(
        'structured_content',
        () => AssistantRichContentModel.tryFromJson(
          payload.object('structured_content'),
        ),
        allowMissing: true,
      );
      return (content: content, isInvalid: false);
    } on FormatException {
      return (content: null, isInvalid: true);
    }
  }
}
