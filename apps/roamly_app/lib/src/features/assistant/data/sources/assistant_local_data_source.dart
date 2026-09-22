import 'package:roamly_app/src/features/assistant/domain/entities/assistant_conversation.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message_delivery_state.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_request.dart';
import 'package:roamly_app/src/features/assistant/domain/policies/assistant_policy.dart';

/// Local persistence contract for assistant conversation history.
///
/// This abstraction does not expose Drift tables, SQLite details, or generated
/// database records to the repository and presentation layers.
abstract interface class AssistantLocalDataSource {
  /// Watches the most recently updated conversations.
  ///
  /// Results are ordered from newest to oldest.
  Stream<List<AssistantConversation>> watchConversations({
    int limit = AssistantPolicy.defaultConversationsLimit,
  });

  /// Watches the latest messages of a conversation.
  ///
  /// The returned list is ordered chronologically from oldest to newest.
  Stream<List<AssistantMessage>> watchMessages({
    required String conversationLocalId,
    int limit = AssistantPolicy.defaultMessagesLimit,
  });

  Future<AssistantConversation?> getConversation({required String localId});
  Future<AssistantMessage?> getUserMessageByClientMessageId({
    required String clientMessageId,
  });
  Future<AssistantConversation?> getConversationByRemoteId({
    required String remoteId,
  });

  /// Loads messages older than the supplied cursor.
  ///
  /// [beforeCreatedAt] and [beforeId] form a stable keyset pagination cursor.
  /// Results are returned from oldest to newest.
  Future<List<AssistantMessage>> getMessagesBefore({
    required String conversationLocalId,
    required DateTime beforeCreatedAt,
    required String beforeId,
    int limit = AssistantPolicy.defaultMessagesLimit,
  });

  Future<void> upsertConversation(AssistantConversation conversation);

  Future<void> upsertMessage(AssistantMessage message);

  /// Stores a conversation and its messages atomically.
  ///
  /// If any write fails, the complete transaction is rolled back.
  Future<void> upsertConversationWithMessages({
    required AssistantConversation conversation,
    required Iterable<AssistantMessage> messages,
  });

  /// Atomically stores a new user message and its durable outbound request.
  Future<void> cachePendingRequest({
    required AssistantConversation conversation,
    required AssistantMessage message,
    required AssistantRequest request,
  });

  /// Returns pending requests in stable creation order for reconnect replay.
  Future<List<AssistantRequest>> getPendingRequests({
    int limit = AssistantPolicy.pendingReplayBatchSize,
    DateTime? afterCreatedAt,
    String? afterClientMessageId,
  });

  Future<AssistantRequest?> getPendingRequest({
    required String clientMessageId,
  });

  /// Atomically fails an unsent user message and removes its outbox record.
  /// Already accepted or completed messages are preserved.
  Future<void> failPendingRequest({required String clientMessageId});

  Future<void> deletePendingRequest({required String clientMessageId});

  Future<void> updateMessageDeliveryState({
    required String messageId,
    required AssistantMessageDeliveryState deliveryState,
    required DateTime updatedAt,
  });

  Future<void> deleteConversation({required String localId});

  /// Removes all locally stored assistant history for the active user.
  Future<void> clear();
}
