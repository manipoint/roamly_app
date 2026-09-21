import 'package:roamly_core/roamly_core.dart';

import '../policies/assistant_policy.dart';

final class AssistantRequest {
  AssistantRequest({
    required String conversationLocalId,
    required String clientMessageId,
    required String message,
    required DateTime createdAt,
    String locale = 'en',
    String? conversationId,
    String? tripId,
  }) : conversationLocalId = RoamlyValueGuards.requireUuid(
         conversationLocalId,
         field: 'conversationLocalId',
       ),
       clientMessageId = RoamlyValueGuards.requireUuid(
         clientMessageId,
         field: 'clientMessageId',
       ),
       conversationId = RoamlyValueGuards.requireOptionalUuid(
         conversationId,
         field: 'conversationId',
       ),
       tripId = RoamlyValueGuards.requireOptionalUuid(tripId, field: 'tripId'),
       message = AssistantPolicy.normalizeMessage(message),
       locale = AssistantPolicy.normalizeLocale(locale),
       createdAt = RoamlyValueNormalizers.utc(createdAt);

  final String conversationLocalId;
  final String clientMessageId;
  final String? conversationId;
  final String? tripId;
  final String message;
  final String locale;
  final DateTime createdAt;

  /// Whether two requests represent the same backend idempotency payload.
  ///
  /// Local persistence stores timestamps at millisecond precision, so
  /// sub-millisecond differences must not turn a valid replay into a conflict.
  bool hasSameIdempotencyPayloadAs(AssistantRequest other) {
    return conversationLocalId == other.conversationLocalId &&
        clientMessageId == other.clientMessageId &&
        conversationId == other.conversationId &&
        tripId == other.tripId &&
        message == other.message &&
        locale == other.locale &&
        createdAt.millisecondsSinceEpoch ==
            other.createdAt.millisecondsSinceEpoch;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AssistantRequest &&
            conversationLocalId == other.conversationLocalId &&
            clientMessageId == other.clientMessageId &&
            conversationId == other.conversationId &&
            tripId == other.tripId &&
            message == other.message &&
            locale == other.locale &&
            createdAt == other.createdAt;
  }

  @override
  int get hashCode => Object.hash(
    conversationLocalId,
    clientMessageId,
    conversationId,
    tripId,
    message,
    locale,
    createdAt,
  );
}
