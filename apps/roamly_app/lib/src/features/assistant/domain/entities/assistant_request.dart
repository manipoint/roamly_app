import 'package:roamly_core/roamly_core.dart';

import '../policies/assistant_request_policy.dart';

final class AssistantRequest {
  AssistantRequest({
    required String clientMessageId,
    required String message,
    required DateTime createdAt,
    String locale = 'en',
    String? conversationId,
    String? tripId,
  }) : clientMessageId = RoamlyValueGuards.requireUuid(
         clientMessageId,
         field: 'clientMessageId',
       ),
       conversationId = RoamlyValueGuards.requireOptionalUuid(
         conversationId,
         field: 'conversationId',
       ),
       tripId = RoamlyValueGuards.requireOptionalUuid(tripId, field: 'tripId'),
       message = AssistantRequestPolicy.normalizeMessage(message),
       locale = AssistantRequestPolicy.normalizeLocale(locale),
       createdAt = RoamlyValueNormalizers.utc(createdAt);

  final String clientMessageId;
  final String? conversationId;
  final String? tripId;
  final String message;
  final String locale;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AssistantRequest &&
            clientMessageId == other.clientMessageId &&
            conversationId == other.conversationId &&
            tripId == other.tripId &&
            message == other.message &&
            locale == other.locale &&
            createdAt == other.createdAt;
  }

  @override
  int get hashCode => Object.hash(
    clientMessageId,
    conversationId,
    tripId,
    message,
    locale,
    createdAt,
  );
}
