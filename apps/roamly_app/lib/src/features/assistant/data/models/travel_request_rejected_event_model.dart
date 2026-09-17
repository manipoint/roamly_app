import '../serialization/assistant_event_reader.dart';
import 'assistant_incoming_event_model.dart';

enum TravelRequestRejectionCode {
  conversationNotFound,
  clientMessageConflict,
  tripNotFound,
  unknown,
}

final class TravelRequestRejectedEventModel
    implements AssistantIncomingEventModel {
  @override
  final DateTime sentAt;
  final String clientMessageId;
  final TravelRequestRejectionCode code;

  const TravelRequestRejectedEventModel._({
    required this.sentAt,
    required this.clientMessageId,
    required this.code,
  });
  factory TravelRequestRejectedEventModel.fromJson(Map<String, Object?> json) {
    final event = AssistantEventReader.fromJson(
      json,
      expectedType: 'travel.request.rejected',
    );
    final rawCode = event.payload.string('code', minLength: 1);
    final code = switch (rawCode) {
      'conversation_not_found' =>
        TravelRequestRejectionCode.conversationNotFound,
      'client_message_conflict' =>
        TravelRequestRejectionCode.clientMessageConflict,
      'trip_not_found' => TravelRequestRejectionCode.tripNotFound,
      _ => TravelRequestRejectionCode.unknown,
    };
    return TravelRequestRejectedEventModel._(
      sentAt: event.sentAt,
      clientMessageId: event.uuid('client_message_id'),
      code: code,
    );
  }
}
