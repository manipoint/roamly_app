import 'package:roamly_core/roamly_core.dart';

/// A locally persisted assistant conversation.
///
/// [localId] always exists and is used by the local database and UI.
/// [remoteId] remains null until the backend creates or accepts the
/// conversation.
final class AssistantConversation {
  final String localId;
  final String? remoteId;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;

  AssistantConversation({
    required String localId,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? title,
    String? remoteId,
  }) : localId = RoamlyValueGuards.requireUuid(localId, field: 'localId'),
       remoteId = RoamlyValueGuards.requireOptionalUuid(
         remoteId,
         field: 'remoteId',
       ),
       title = RoamlyValueNormalizers.optionalTrimmed(title),
       createdAt = RoamlyValueNormalizers.utc(createdAt),
       updatedAt = _normalizeUpdatedAt(
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  static DateTime _normalizeUpdatedAt({
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    final normalizedCreatedAt = RoamlyValueNormalizers.utc(createdAt);
    final normalizedUpdatedAt = RoamlyValueNormalizers.utc(updatedAt);
    return RoamlyValueGuards.requireNotBefore(
      value: normalizedUpdatedAt,
      minimum: normalizedCreatedAt,
      field: 'updatedAt',
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AssistantConversation &&
            localId == other.localId &&
            remoteId == other.remoteId &&
            title == other.title &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode =>
      Object.hash(localId, remoteId, title, createdAt, updatedAt);
}
