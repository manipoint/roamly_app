import 'package:drift/drift.dart';
import 'package:roamly_app/src/features/assistant/data/sources/assistant_local_data_source.dart';

import '../../domain/entities/assistant_conversation.dart';
import '../../domain/entities/assistant_message.dart';
import '../../domain/entities/assistant_message_delivery_state.dart';
import '../database/assistant_database.dart';
import '../policies/assistant_data_policy.dart';

final class DriftAssistantLocalDataSource implements AssistantLocalDataSource {
  const DriftAssistantLocalDataSource({
    required AssistantDatabase database,
    required String ownerId,
  }) : _database = database,
       _ownerId = ownerId;
  static const int _maximumConversationLimit = 100;
  static const int _maximumMessageLimit = 200;

  final AssistantDatabase _database;
  final String _ownerId;

  @override
  Future<void> clear() {
    // TODO: implement clear
    throw UnimplementedError();
  }

  @override
  Future<void> deleteConversation({required String localId}) {
    // TODO: implement deleteConversation
    throw UnimplementedError();
  }

  @override
  Future<AssistantConversation?> getConversationByRemoteId({
    required String remoteId,
  }) {
    // TODO: implement getConversationByRemoteId
    throw UnimplementedError();
  }

  @override
  Future<List<AssistantMessage>> getMessagesBefore({
    required String conversationLocalId,
    required DateTime beforeCreatedAt,
    required String beforeId,
    int limit = AssistantDataPolicy.defaultConversationsLimit,
  }) {
    // TODO: implement getMessagesBefore
    throw UnimplementedError();
  }

  @override
  Future<void> upsertConversation(AssistantConversation conversation) {
    // TODO: implement upsertConversation
    throw UnimplementedError();
  }
  @override
  Future<void> upsertConversationWithMessages({
    required AssistantConversation conversation,
    required Iterable<AssistantMessage> messages,
  }) {
    // TODO: implement upsertConversationWithMessages
    throw UnimplementedError();
  }

  @override
  Future<void> upsertMessage(AssistantMessage message) {
    // TODO: implement upsertMessage
    throw UnimplementedError();
  }

  @override
  Stream<List<AssistantConversation>> watchConversations({
    int limit = AssistantDataPolicy.defaultConversationsLimit,
  }) {
    _validateLimit(limit, maximum: _maximumConversationLimit);
    final query = _database.select(_database.assistantConversations)
      ..where((row) => row.ownerId.equals(_ownerId))
      ..orderBy([
        (row) => OrderingTerm.desc(row.updatedAtEpochMs),
        (row) => OrderingTerm.desc(row.localId),
      ])
      ..limit(limit);
    return query.watch().map(
      (records) => records.map(_conversationFromRecord).toList(growable: false),
    );
  }

  @override
  Stream<List<AssistantMessage>> watchMessages({
    required String conversationLocalId,
    int limit = AssistantDataPolicy.defaultMessagesLimit,
  }) {
    // TODO: implement watchMessages
    throw UnimplementedError();
  }

  static void _validateLimit(int limit, {required int maximum}) {
    if (limit < 1 || limit > maximum) {
      throw RangeError.range(limit, 1, maximum, 'limit');
    }
  }

  static AssistantConversation _conversationFromRecord(
    AssistantConversationRecord e,
  ) {}

  
}
