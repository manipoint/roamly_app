import 'package:roamly_app/src/app/validator/roamly_value_validators.dart';

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
    _validateUuid(clientMessageId, 'client_message_id');

    if (conversationId != null) {
      _validateUuid(conversationId, 'conversation_id');
    }

    if (tripId != null) {
      _validateUuid(tripId, 'trip_id');
    }

    final normalizedMessage = message.trim();
    final messageLength = normalizedMessage.runes.length;

    if (messageLength < 1 || messageLength > 2000) {
      throw ArgumentError(
        'Message must contain between 1 and 2000 characters.',
      );
    }

    final normalizedLocale = locale.trim();
    final localeLength = normalizedLocale.runes.length;

    if (localeLength < 2 || localeLength > 35) {
      throw ArgumentError('Locale must contain between 2 and 35 characters.');
    }

    return TravelRequestEventModel._(
      clientMessageId: clientMessageId,
      conversationId: conversationId,
      tripId: tripId,
      message: normalizedMessage,
      locale: normalizedLocale,
      sentAt: sentAt.toUtc(),
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

  static void _validateUuid(String value, String field) {
    if (!RoamlyValueValidators.isValidUuid(value)) {
      throw ArgumentError('Invalid UUID field: $field.');
    }
  }
}
