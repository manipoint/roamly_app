import 'package:roamly_core/roamly_core.dart';

import '../../domain/policies/assistant_policy.dart';

final class TravelRequestEventModel {
  const TravelRequestEventModel._({
    required this.clientMessageId,
    required this.message,
    required this.locale,
    required this.sentAt,
    this.conversationId,
    this.tripId,
  });

  final String clientMessageId;
  final String message;
  final String locale;
  final DateTime sentAt;
  final String? conversationId;
  final String? tripId;

  factory TravelRequestEventModel({
    required String clientMessageId,
    required String message,
    required DateTime sentAt,
    String locale = 'en',
    String? conversationId,
    String? tripId,
  }) {
    final validatedClientMessageId = RoamlyValueGuards.requireUuid(
      clientMessageId,
      field: 'client_message_id',
    );
    final validatedConversationId = RoamlyValueGuards.requireOptionalUuid(
      conversationId,
      field: 'conversation_id',
    );
    final validatedTripId = RoamlyValueGuards.requireOptionalUuid(
      tripId,
      field: 'trip_id',
    );
    final normalizedMessage = AssistantPolicy.normalizeMessage(message);
    final normalizedLocale = AssistantPolicy.normalizeLocale(locale);

    return TravelRequestEventModel._(
      clientMessageId: validatedClientMessageId,
      conversationId: validatedConversationId,
      tripId: validatedTripId,
      message: normalizedMessage,
      locale: normalizedLocale,
      sentAt: RoamlyValueNormalizers.utc(sentAt),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'version': 1,
      'type': 'travel.request',
      'sent_at': sentAt.toIso8601String(),
      'payload': <String, Object?>{
        'client_message_id': clientMessageId,
        if (conversationId != null) 'conversation_id': conversationId,
        if (tripId != null) 'trip_id': tripId,
        'message': message,
        'locale': locale,
      },
    };
  }
}
