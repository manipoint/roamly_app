import 'package:drift/drift.dart';
import 'package:roamly_app/src/features/assistant/data/database/assistant_database.dart';
import 'package:roamly_app/src/features/assistant/data/sources/assistant_local_data_source.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_conversation.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message_delivery_state.dart';
import 'package:roamly_core/roamly_core.dart';

final class DriftAssistantLocalDataSource implements AssistantLocalDataSource {
  static const int _maximumConversationLimit = 100;
  static const int _maximumMessageLimit = 200;

  final AssistantDatabase _database;
  final String _ownerId;

  DriftAssistantLocalDataSource({
    required AssistantDatabase database,
    required String ownerId,
  }) : _database = database,
       _ownerId = _validateOwnerId(ownerId);

  @override
  Stream<List<AssistantConversation>> watchConversations({int limit = 50}) {
    _validateLimit(limit, maximum: _maximumConversationLimit);

    final query = _database.select(_database.assistantConversations)
      ..where((row) => row.ownerId.equals(_ownerId))
      ..orderBy([
        (row) => OrderingTerm.desc(row.updatedAtEpochMs),
        (row) => OrderingTerm.desc(row.localId),
      ])
      ..limit(limit);

    return query.watch().map((records) {
      return records.map(_conversationFromRecord).toList(growable: false);
    });
  }

  @override
  Stream<List<AssistantMessage>> watchMessages({
    required String conversationLocalId,
    int limit = 100,
  }) {
    final validatedConversationId = RoamlyValueGuards.requireUuid(
      conversationLocalId,
      field: 'conversationLocalId',
    );

    _validateLimit(limit, maximum: _maximumMessageLimit);

    final query = _database.select(_database.assistantMessages)
      ..where(
        (row) =>
            row.ownerId.equals(_ownerId) &
            row.conversationLocalId.equals(validatedConversationId),
      )
      ..orderBy([
        (row) => OrderingTerm.desc(row.createdAtEpochMs),
        (row) => OrderingTerm.desc(row.id),
      ])
      ..limit(limit);

    return query.watch().map((records) {
      return records.reversed.map(_messageFromRecord).toList(growable: false);
    });
  }

  @override
  Future<AssistantConversation?> getConversation({
    required String localId,
  }) async {
    final validatedLocalId = RoamlyValueGuards.requireUuid(
      localId,
      field: 'localId',
    );

    final query = _database.select(_database.assistantConversations)
      ..where(
        (row) =>
            row.ownerId.equals(_ownerId) & row.localId.equals(validatedLocalId),
      );

    final record = await query.getSingleOrNull();

    return record == null ? null : _conversationFromRecord(record);
  }

  @override
  Future<AssistantConversation?> getConversationByRemoteId({
    required String remoteId,
  }) async {
    final validatedRemoteId = RoamlyValueGuards.requireUuid(
      remoteId,
      field: 'remoteId',
    );

    final query = _database.select(_database.assistantConversations)
      ..where(
        (row) =>
            row.ownerId.equals(_ownerId) &
            row.remoteId.equals(validatedRemoteId),
      );

    final record = await query.getSingleOrNull();

    return record == null ? null : _conversationFromRecord(record);
  }

  @override
  Future<List<AssistantMessage>> getMessagesBefore({
    required String conversationLocalId,
    required DateTime beforeCreatedAt,
    required String beforeId,
    int limit = 50,
  }) async {
    final validatedConversationId = RoamlyValueGuards.requireUuid(
      conversationLocalId,
      field: 'conversationLocalId',
    );

    final validatedBeforeId = RoamlyValueGuards.requireUuid(
      beforeId,
      field: 'beforeId',
    );

    _validateLimit(limit, maximum: _maximumMessageLimit);

    final beforeEpochMs = beforeCreatedAt.toUtc().millisecondsSinceEpoch;

    final query = _database.select(_database.assistantMessages)
      ..where(
        (row) =>
            row.ownerId.equals(_ownerId) &
            row.conversationLocalId.equals(validatedConversationId) &
            (row.createdAtEpochMs.isSmallerThanValue(beforeEpochMs) |
                (row.createdAtEpochMs.equals(beforeEpochMs) &
                    row.id.isSmallerThanValue(validatedBeforeId))),
      )
      ..orderBy([
        (row) => OrderingTerm.desc(row.createdAtEpochMs),
        (row) => OrderingTerm.desc(row.id),
      ])
      ..limit(limit);

    final records = await query.get();

    return records.reversed.map(_messageFromRecord).toList(growable: false);
  }

  @override
  Future<void> upsertConversation(AssistantConversation conversation) {
    return _database.transaction(() async {
      await _upsertConversation(conversation);
    });
  }

  @override
  Future<void> upsertMessage(AssistantMessage message) {
    return _database.transaction(() async {
      await _ensureConversationBelongsToOwner(message.conversationLocalId);

      await _upsertMessage(message);
    });
  }

@override
  Future<void> upsertConversationWithMessages({
    required AssistantConversation conversation,
    required Iterable<AssistantMessage> messages,
  }) {
    final messageList = messages.toList(growable: false);

    for (final message in messageList) {
      if (message.conversationLocalId != conversation.localId) {
        throw ArgumentError(
          'Every message must belong to the supplied conversation.',
        );
      }
    }

    return _database.transaction(() async {
      await _upsertConversation(conversation);

      for (final message in messageList) {
        await _upsertMessage(message);
      }
    });
  }

  @override
  Future<void> updateMessageDeliveryState({
    required String messageId,
    required AssistantMessageDeliveryState deliveryState,
    required DateTime updatedAt,
  }) async {
    final validatedMessageId = RoamlyValueGuards.requireUuid(
      messageId,
      field: 'messageId',
    );

    final affectedRows =
        await (_database.update(_database.assistantMessages)..where(
              (row) =>
                  row.ownerId.equals(_ownerId) &
                  row.id.equals(validatedMessageId),
            ))
            .write(
              AssistantMessagesCompanion(
                deliveryState: Value(deliveryState),
                updatedAtEpochMs: Value(
                  updatedAt.toUtc().millisecondsSinceEpoch,
                ),
              ),
            );

    if (affectedRows == 0) {
      throw StateError('The assistant message does not exist.');
    }
  }

  @override
  Future<void> deleteConversation({required String localId}) async {
    final validatedLocalId = RoamlyValueGuards.requireUuid(
      localId,
      field: 'localId',
    );

    await (_database.delete(_database.assistantConversations)..where(
          (row) =>
              row.ownerId.equals(_ownerId) &
              row.localId.equals(validatedLocalId),
        ))
        .go();

    // Messages are removed through ON DELETE CASCADE.
  }

  @override
  Future<void> clear() {
    return _database.transaction(() async {
      // Explicit message deletion also protects cleanup if a previously
      // created database had foreign keys disabled.
      await (_database.delete(
        _database.assistantMessages,
      )..where((row) => row.ownerId.equals(_ownerId))).go();

      await (_database.delete(
        _database.assistantConversations,
      )..where((row) => row.ownerId.equals(_ownerId))).go();
    });
  }

  Future<void> _upsertConversation(AssistantConversation conversation) async {
    await _ensureConversationRecordOwnership(conversation.localId);

    await _database
        .into(_database.assistantConversations)
        .insertOnConflictUpdate(
          AssistantConversationsCompanion.insert(
            ownerId: _ownerId,
            localId: conversation.localId,
            remoteId: Value(conversation.remoteId),
            title: Value(conversation.title),
            createdAtEpochMs: conversation.createdAt.millisecondsSinceEpoch,
            updatedAtEpochMs: conversation.updatedAt.millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> _upsertMessage(AssistantMessage message) async {
    await _ensureMessageRecordOwnership(message.id);

    await _database
        .into(_database.assistantMessages)
        .insertOnConflictUpdate(
          AssistantMessagesCompanion.insert(
            ownerId: _ownerId,
            id: message.id,
            conversationLocalId: message.conversationLocalId,
            clientMessageId: message.clientMessageId,
            assistantMessageId: Value(message.assistantMessageId),
            itineraryId: Value(message.itineraryId),
            author: message.author,
            content: message.content,
            deliveryState: message.deliveryState,
            createdAtEpochMs: message.createdAt.millisecondsSinceEpoch,
            updatedAtEpochMs: message.updatedAt.millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> _ensureConversationBelongsToOwner(
    String conversationLocalId,
  ) async {
    final query = _database.selectOnly(_database.assistantConversations)
      ..addColumns([_database.assistantConversations.ownerId])
      ..where(
        _database.assistantConversations.localId.equals(conversationLocalId),
      );

    final record = await query.getSingleOrNull();

    if (record == null) {
      throw StateError('The parent assistant conversation does not exist.');
    }

    final storedOwnerId = record.read(_database.assistantConversations.ownerId);

    if (storedOwnerId != _ownerId) {
      throw StateError('The assistant conversation belongs to another user.');
    }
  }

  Future<void> _ensureConversationRecordOwnership(String localId) async {
    final query = _database.selectOnly(_database.assistantConversations)
      ..addColumns([_database.assistantConversations.ownerId])
      ..where(_database.assistantConversations.localId.equals(localId));

    final record = await query.getSingleOrNull();

    if (record == null) return;

    final storedOwnerId = record.read(_database.assistantConversations.ownerId);

    if (storedOwnerId != _ownerId) {
      throw StateError('The conversation identifier belongs to another user.');
    }
  }

  Future<void> _ensureMessageRecordOwnership(String messageId) async {
    final query = _database.selectOnly(_database.assistantMessages)
      ..addColumns([_database.assistantMessages.ownerId])
      ..where(_database.assistantMessages.id.equals(messageId));

    final record = await query.getSingleOrNull();

    if (record == null) return;

    final storedOwnerId = record.read(_database.assistantMessages.ownerId);

    if (storedOwnerId != _ownerId) {
      throw StateError('The message identifier belongs to another user.');
    }
  }

  static AssistantConversation _conversationFromRecord(
    AssistantConversationRecord record,
  ) {
    return AssistantConversation(
      localId: record.localId,
      remoteId: record.remoteId,
      title: record.title,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        record.createdAtEpochMs,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        record.updatedAtEpochMs,
        isUtc: true,
      ),
    );
  }

  static AssistantMessage _messageFromRecord(AssistantMessageRecord record) {
    return AssistantMessage(
      id: record.id,
      conversationLocalId: record.conversationLocalId,
      clientMessageId: record.clientMessageId,
      assistantMessageId: record.assistantMessageId,
      itineraryId: record.itineraryId,
      author: record.author,
      content: record.content,
      deliveryState: record.deliveryState,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        record.createdAtEpochMs,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        record.updatedAtEpochMs,
        isUtc: true,
      ),
    );
  }

  static String _validateOwnerId(String ownerId) {
    final normalizedOwnerId = RoamlyValueNormalizers.trimmed(ownerId);

    return RoamlyValueGuards.requireNonBlank(
      normalizedOwnerId,
      field: 'ownerId',
    );
  }

  static void _validateLimit(int limit, {required int maximum}) {
    if (limit < 1 || limit > maximum) {
      throw RangeError.range(limit, 1, maximum, 'limit');
    }
  }
}
