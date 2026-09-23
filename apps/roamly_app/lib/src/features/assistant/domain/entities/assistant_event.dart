import 'package:roamly_core/roamly_core.dart';

import 'assistant_clarification.dart';

sealed class AssistantEvent {
  AssistantEvent({required DateTime occurredAt})
    : occurredAt = RoamlyValueNormalizers.utc(occurredAt);

  final DateTime occurredAt;
  String get clientMessageId;
}

enum AssistantRequestRejectionReason {
  conversationNotFound,
  clientMessageConflict,
  tripNotFound,
  unknown,
}

enum AssistantResponseFailureReason {
  providerError,
  generationFailed,
  attemptsExhausted,
  unknown,
}

final class AssistantRequestAccepted extends AssistantEvent {
  AssistantRequestAccepted({
    required super.occurredAt,
    required String clientMessageId,
    required String conversationId,
  }) : clientMessageId = RoamlyValueGuards.requireUuid(
         clientMessageId,
         field: 'clientMessageId',
       ),
       conversationId = RoamlyValueGuards.requireUuid(
         conversationId,
         field: 'conversationId',
       );
  @override
  final String clientMessageId;
  final String conversationId;
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AssistantRequestAccepted &&
            occurredAt == other.occurredAt &&
            clientMessageId == other.clientMessageId &&
            conversationId == other.conversationId;
  }

  @override
  int get hashCode => Object.hash(occurredAt, clientMessageId, conversationId);
}

final class AssistantRequestRejected extends AssistantEvent {
  AssistantRequestRejected({
    required super.occurredAt,
    required String clientMessageId,
    required this.reason,
  }) : clientMessageId = RoamlyValueGuards.requireUuid(
         clientMessageId,
         field: 'clientMessageId',
       );
  @override
  final String clientMessageId;
  final AssistantRequestRejectionReason reason;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AssistantRequestRejected &&
            occurredAt == other.occurredAt &&
            clientMessageId == other.clientMessageId &&
            reason == other.reason;
  }

  @override
  int get hashCode => Object.hash(occurredAt, clientMessageId, reason);
}

final class AssistantResponseProcessing extends AssistantEvent {
  AssistantResponseProcessing({
    required super.occurredAt,
    required String clientMessageId,
    required String conversationId,
  }) : clientMessageId = RoamlyValueGuards.requireUuid(
         clientMessageId,
         field: 'clientMessageId',
       ),
       conversationId = RoamlyValueGuards.requireUuid(
         conversationId,
         field: 'conversationId',
       );
  @override
  final String clientMessageId;
  final String conversationId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AssistantResponseProcessing &&
            occurredAt == other.occurredAt &&
            clientMessageId == other.clientMessageId &&
            conversationId == other.conversationId;
  }

  @override
  int get hashCode => Object.hash(occurredAt, clientMessageId, conversationId);
}

sealed class AssistantResponseWithMessage extends AssistantEvent {
  AssistantResponseWithMessage({required super.occurredAt});

  String get conversationId;
  String get assistantMessageId;
  String get content;
  bool get isDuplicate;
  String? get itineraryId;
}

final class AssistantResponseCompleted extends AssistantResponseWithMessage {
  AssistantResponseCompleted({
    required super.occurredAt,
    required String clientMessageId,
    required String conversationId,
    required String assistantMessageId,
    required String content,
    required this.isDuplicate,
    String? itineraryId,
  }) : clientMessageId = RoamlyValueGuards.requireUuid(
         clientMessageId,
         field: 'clientMessageId',
       ),
       conversationId = RoamlyValueGuards.requireUuid(
         conversationId,
         field: 'conversationId',
       ),
       assistantMessageId = RoamlyValueGuards.requireUuid(
         assistantMessageId,
         field: 'assistantMessageId',
       ),
       content = RoamlyValueGuards.requireNonBlank(content, field: 'content'),
       itineraryId = RoamlyValueGuards.requireOptionalUuid(
         itineraryId,
         field: 'itineraryId',
       );
  @override
  final String clientMessageId;
  @override
  final String conversationId;
  @override
  final String assistantMessageId;
  @override
  final String content;
  @override
  final bool isDuplicate;
  @override
  final String? itineraryId;
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AssistantResponseCompleted &&
            occurredAt == other.occurredAt &&
            clientMessageId == other.clientMessageId &&
            conversationId == other.conversationId &&
            assistantMessageId == other.assistantMessageId &&
            content == other.content &&
            isDuplicate == other.isDuplicate &&
            itineraryId == other.itineraryId;
  }

  @override
  int get hashCode => Object.hash(
    occurredAt,
    clientMessageId,
    conversationId,
    assistantMessageId,
    content,
    isDuplicate,
    itineraryId,
  );
}

final class AssistantInputRequired extends AssistantResponseWithMessage {
  AssistantInputRequired({
    required super.occurredAt,
    required String clientMessageId,
    required String conversationId,
    required String assistantMessageId,
    required String content,
    required this.isDuplicate,
    required this.clarification,
  }) : clientMessageId = RoamlyValueGuards.requireUuid(
         clientMessageId,
         field: 'clientMessageId',
       ),
       conversationId = RoamlyValueGuards.requireUuid(
         conversationId,
         field: 'conversationId',
       ),
       assistantMessageId = RoamlyValueGuards.requireUuid(
         assistantMessageId,
         field: 'assistantMessageId',
       ),
       content = RoamlyValueGuards.requireNonBlank(content, field: 'content');

  @override
  final String clientMessageId;
  @override
  final String conversationId;
  @override
  final String assistantMessageId;
  @override
  final String content;
  @override
  final bool isDuplicate;
  final AssistantClarification clarification;

  @override
  String? get itineraryId => null;
}

final class AssistantResponseFailed extends AssistantEvent {
  AssistantResponseFailed({
    required super.occurredAt,
    required String clientMessageId,
    required String conversationId,
    required this.reason,
  }) : clientMessageId = RoamlyValueGuards.requireUuid(
         clientMessageId,
         field: 'clientMessageId',
       ),
       conversationId = RoamlyValueGuards.requireUuid(
         conversationId,
         field: 'conversationId',
       );
  @override
  final String clientMessageId;
  final String conversationId;
  final AssistantResponseFailureReason reason;
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AssistantResponseFailed &&
            occurredAt == other.occurredAt &&
            clientMessageId == other.clientMessageId &&
            conversationId == other.conversationId &&
            reason == other.reason;
  }

  @override
  int get hashCode =>
      Object.hash(occurredAt, clientMessageId, conversationId, reason);
}
