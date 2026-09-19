import 'package:roamly_app/src/features/assistant/data/policies/assistant_data_policy.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_conversation.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message_delivery_state.dart';

/// Local persistence contract for assistant conversation history.
///
/// This abstraction does not expose Drift, tables, or generated
/// database records to the repository or presentation layers.
abstract interface class AssistantLocalDataSource {
  /// Watches the most recently updated conversations.
  ///
  /// Results are ordered from newest to oldest.
  Stream<List<AssistantConversation>> watchConversations({
    int limit = AssistantDataPolicy.defaultConversationsLimit,
  });

  /// Watches the latest messages of a conversation.
  ///
  /// Although the database fetches the newest [limit] messages, the returned
  /// list is ordered chronologically from oldest to newest for the UI.
  Stream<List<AssistantMessage>> watchMessages({
    required String conversationLocalId,
    int limit = AssistantDataPolicy.defaultMessagesLimit,
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
    int limit = AssistantDataPolicy.defaultConversationsLimit,
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
  Future<void> deleteConversation({required String localId});

  /// Removes assistant history belonging to the active user.
  Future<void> clear();
}
