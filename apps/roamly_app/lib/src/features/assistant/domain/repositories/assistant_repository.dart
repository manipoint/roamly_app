import 'package:roamly_app/src/features/assistant/domain/entities/assistant_event.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_request.dart';

import '../entities/assistant_conversation.dart';
import '../policies/assistant_policy.dart';

/// Domain-facing access point for the realtime travel assistant.
///
/// Transport details such as WebSocket frames, heartbeat events, JSON models,
/// reconnect generations, and protocol configuration remain in the data layer.
abstract interface class AssistantRepository {
  Stream<AssistantEvent> get events;
  Stream<bool> get readinessChanges;
  bool get isReady;
  Stream<List<AssistantConversation>> watchConversations({
    int limit = AssistantPolicy.defaultConversationsLimit,
  });
  Stream<List<AssistantMessage>> watchMessages({
    required String conversationLocalId,
    int limit = AssistantPolicy.defaultMessagesLimit,
  });
  Future<List<AssistantMessage>> getMessagesBefore({
    required String conversationLocalId,
    required String beforeId,
    required DateTime beforeCreatedAt,
    int limit = AssistantPolicy.defaultMessagesLimit,
  });

  void connect();
  Future<void> disconnect();
  Future<void> sendRequest( AssistantRequest request);
  Future<void> deleteConversation({required String localId});
  Future<void> clearLocalHistory();
  Future<void> dispose();
}
