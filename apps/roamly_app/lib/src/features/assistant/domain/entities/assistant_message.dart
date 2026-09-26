import 'package:roamly_app/src/features/assistant/domain/entities/assistant_rich_content.dart';
import 'package:roamly_core/roamly_core.dart';

import 'assistant_message_delivery_state.dart';

enum AssistantMessageAuthor { user, assistant }

/// A message stored in the local assistant conversation history.
///
/// Every message has a local [id]. User messages use [clientMessageId] for
/// idempotency. Assistant messages additionally contain [assistantMessageId].
final class AssistantMessage {
  /// Stable client-side identifier used as the local database key.
  final String id;

  /// Local conversation ID.
  ///
  /// This references [AssistantConversation.localId], not its remote ID.
  final String conversationLocalId;

  /// Client request ID used to correlate user and assistant messages.
  final String clientMessageId;

  /// Backend-generated assistant message ID.
  ///
  /// Required for assistant-authored messages and absent for user messages.
  final String? assistantMessageId;

  /// Generated itinerary associated with an assistant response.
  final String? itineraryId;
  final AssistantRichContent? richContent;
  final AssistantMessageAuthor author;
  final String content;

  /// Safe failure code, never raw backend error text.
  final String? failureCode;
  final AssistantMessageDeliveryState deliveryState;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AssistantMessage._({
    required this.id,
    required this.conversationLocalId,
    required this.clientMessageId,
    required this.assistantMessageId,
    required this.itineraryId,
    required this.richContent,
    required this.author,
    required this.content,
    required this.failureCode,
    required this.deliveryState,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssistantMessage({
    required String id,
    required String conversationLocalId,
    required String clientMessageId,
    required AssistantMessageAuthor author,
    required String content,
    required AssistantMessageDeliveryState deliveryState,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? assistantMessageId,
    String? itineraryId,
    String? failureCode,
    AssistantRichContent? richContent,
  }) {
    final validatedId = RoamlyValueGuards.requireUuid(id, field: 'id');
    final validatedConversationId = RoamlyValueGuards.requireUuid(
      conversationLocalId,
      field: 'conversationLocalId',
    );
    final validatedClientMessageId = RoamlyValueGuards.requireUuid(
      clientMessageId,
      field: 'clientMessageId',
    );
    final validatedAssistantMessageId = RoamlyValueGuards.requireOptionalUuid(
      assistantMessageId,
      field: 'assistantMessageId',
    );
    final validatedItineraryId = RoamlyValueGuards.requireOptionalUuid(
      itineraryId,
      field: 'itineraryId',
    );
    _validateAuthorSpecificFields(
      author: author,
      assistantMessageId: validatedAssistantMessageId,
      itineraryId: validatedItineraryId,
      richContent: richContent,
    );
    final validatedContent = RoamlyValueGuards.requireNonBlank(
      content,
      field: 'content',
    );
    final normalizedCreatedAt = RoamlyValueNormalizers.utc(createdAt);
    final normalizedUpdatedAt = RoamlyValueNormalizers.utc(updatedAt);
    RoamlyValueGuards.requireNotBefore(
      value: normalizedUpdatedAt,
      minimum: normalizedCreatedAt,
      field: 'updatedAt',
    );
    return AssistantMessage._(
      id: validatedId,
      conversationLocalId: validatedConversationId,
      clientMessageId: validatedClientMessageId,
      assistantMessageId: validatedAssistantMessageId,
      author: author,
      content: validatedContent,
      failureCode: deliveryState == AssistantMessageDeliveryState.failed
          ? failureCode
          : null,
      deliveryState: deliveryState,
      createdAt: normalizedCreatedAt,
      updatedAt: normalizedUpdatedAt,
      itineraryId: validatedItineraryId,
      richContent: richContent,
    );
  }
  static void _validateAuthorSpecificFields({
    required AssistantMessageAuthor author,
    required String? assistantMessageId,
    required String? itineraryId,
    required AssistantRichContent? richContent,
  }) {
    switch (author) {
      case AssistantMessageAuthor.user:
        if (assistantMessageId != null) {
          throw ArgumentError(
            'A user message cannot have an assistantMessageId.',
          );
        }

        if (itineraryId != null) {
          throw ArgumentError('A user message cannot have an itineraryId.');
        }
        if (richContent != null) {
          throw ArgumentError(
            'A user message cannot have assistant rich content.',
          );
        }

      case AssistantMessageAuthor.assistant:
        if (assistantMessageId == null) {
          throw ArgumentError(
            'An assistant message requires an assistantMessageId.',
          );
        }
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AssistantMessage &&
            id == other.id &&
            conversationLocalId == other.conversationLocalId &&
            clientMessageId == other.clientMessageId &&
            assistantMessageId == other.assistantMessageId &&
            author == other.author &&
            content == other.content &&
            failureCode == other.failureCode &&
            deliveryState == other.deliveryState &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt &&
            richContent == other.richContent &&
            itineraryId == other.itineraryId;
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationLocalId,
    clientMessageId,
    assistantMessageId,
    author,
    content,
    deliveryState,
    createdAt,
    updatedAt,
    itineraryId,
    richContent,
    failureCode,
  );
}
