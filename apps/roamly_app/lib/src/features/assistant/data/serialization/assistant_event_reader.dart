import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_networking/roamly_networking.dart';

final class AssistantEventReader {
  const AssistantEventReader._({required this.sentAt, required this.payload});

  static const protocolVersion = 1;

  final DateTime sentAt;
  final JsonReader payload;

  factory AssistantEventReader.fromJson(
    Map<String, Object?> json, {
    required String expectedType,
  }) {
    final envelope = JsonReader(json);
    envelope.integer('version', min: protocolVersion, max: protocolVersion);
    if (envelope.string('type') != expectedType) {
      throw const FormatException('Unexpected Assistant event type.');
    }
    return AssistantEventReader._(
      sentAt: envelope.dateTime('sent_at'),
      payload: JsonReader(envelope.object('payload')),
    );
  }

  String uuid(String field) {
    final value = payload.string(
      field,
      minLength: RoamlyValueValidators.uuidLength,
      maxLength: RoamlyValueValidators.uuidLength,
    );
    if (!RoamlyValueValidators.isValidUuid(value)) {
      throw FormatException('Invalid UUID field: $field.');
    }
    return value;
  }
}
