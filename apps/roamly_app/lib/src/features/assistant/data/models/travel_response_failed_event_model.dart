import '../serialization/assistant_event_reader.dart';
import 'assistant_incoming_event_model.dart';

enum TravelResponseFailureCode {
  providerError,
  generationFailed,
  attemptsExhausted,
  unknown,
}

final class TravelResponseFailedEventModel
    implements AssistantIncomingEventModel {
  @override
  final DateTime sentAt;
  final String clientMessageId;
  final String conversationId;
  final TravelResponseFailureCode code;

  const TravelResponseFailedEventModel._({
    required this.sentAt,
    required this.clientMessageId,
    required this.conversationId,
    required this.code,
  });
  factory TravelResponseFailedEventModel.fromJson(Map<String, Object?> json) {
    final event = AssistantEventReader.fromJson(
      json,
      expectedType: 'travel.response.failed',
    );
    final payload = event.payload;
    final clientMessageId = event.uuid('client_message_id');
    final conversationId = event.uuid('conversation_id');

    final rawCode = payload.string('code', trim: true, minLength: 1);

    final code = switch (rawCode) {
      'provider_error' => TravelResponseFailureCode.providerError,
      'generation_failed' => TravelResponseFailureCode.generationFailed,
      'attempts_exhausted' => TravelResponseFailureCode.attemptsExhausted,
      _ => TravelResponseFailureCode.unknown,
    };
    return TravelResponseFailedEventModel._(
      sentAt: event.sentAt,
      clientMessageId: clientMessageId,
      conversationId: conversationId,
      code: code,
    );
  }
}
