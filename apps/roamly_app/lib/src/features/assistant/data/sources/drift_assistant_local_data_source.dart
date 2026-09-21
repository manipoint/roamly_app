import 'package:drift/drift.dart';
import 'package:roamly_app/src/features/assistant/data/database/assistant_database.dart';
import 'package:roamly_app/src/features/assistant/data/sources/assistant_local_data_source.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_conversation.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message_delivery_state.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_request.dart';
import 'package:roamly_app/src/features/assistant/domain/policies/assistant_policy.dart';
import 'package:roamly_core/roamly_core.dart';

final class DriftAssistantLocalDataSource implements AssistantLocalDataSource {
  final AssistantDatabase _database;
  final String _ownerId;

  DriftAssistantLocalDataSource({
    required AssistantDatabase database,
    required String ownerId,
  }) : _database = database,
       _ownerId = _validateOwnerId(ownerId);

  @override
  Stream<List<AssistantConversation>> watchConversations({
    int limit = AssistantPolicy.defaultConversationsLimit,
  }) {
    _validateLimit(limit, maximum: AssistantPolicy.maximumConversationsLimit);

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
    int limit = AssistantPolicy.defaultMessagesLimit,
  }) {
    final validatedConversationId = RoamlyValueGuards.requireUuid(
      conversationLocalId,
      field: 'conversationLocalId',
    );

    _validateLimit(limit, maximum: AssistantPolicy.maximumMessagesLimit);

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

    return query.watch().map(
      (records) =>
          records.reversed.map(_messageFromRecord).toList(growable: false),
    );
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
    int limit = AssistantPolicy.defaultMessagesLimit,
  }) async {
    final validatedConversationId = RoamlyValueGuards.requireUuid(
      conversationLocalId,
      field: 'conversationLocalId',
    );

    final validatedBeforeId = RoamlyValueGuards.requireUuid(
      beforeId,
      field: 'beforeId',
    );

    _validateLimit(limit, maximum: AssistantPolicy.maximumMessagesLimit);

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
      await _upsertConversationRecord(conversation);
    });
  }

  @override
  Future<void> upsertMessage(AssistantMessage message) {
    return _database.transaction(() async {
      await _ensureConversationBelongsToOwner(message.conversationLocalId);

      await _upsertMessageRecord(message);
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
      await _upsertConversationRecord(conversation);

      for (final message in messageList) {
        await _upsertMessageRecord(message);
      }
    });
  }

  @override
  Future<void> cachePendingRequest({
    required AssistantConversation conversation,
    required AssistantMessage message,
    required AssistantRequest request,
  }) {
    if (message.author != AssistantMessageAuthor.user ||
        message.deliveryState != AssistantMessageDeliveryState.pending ||
        message.id != request.clientMessageId ||
        message.clientMessageId != request.clientMessageId ||
        message.conversationLocalId != conversation.localId ||
        request.conversationLocalId != conversation.localId ||
        message.content != request.message ||
        message.createdAt.millisecondsSinceEpoch !=
            request.createdAt.millisecondsSinceEpoch) {
      throw ArgumentError(
        'The pending message, request, and conversation do not match.',
      );
    }

    return _database.transaction(() async {
      await _upsertConversationRecord(conversation);
      await _upsertMessageRecord(message);
      await _upsertPendingRequestRecord(request);
    });
  }

  @override
  Future<List<AssistantRequest>> getPendingRequests({
    int limit = AssistantPolicy.pendingReplayBatchSize,
    DateTime? afterCreatedAt,
    String? afterClientMessageId,
  }) async {
    final hasCreatedAtCursor = afterCreatedAt != null;
    final hasClientMessageIdCursor = afterClientMessageId != null;
    if (hasCreatedAtCursor != hasClientMessageIdCursor) {
      throw ArgumentError(
        'afterCreatedAt and afterClientMessageId must be supplied together.',
      );
    }
    _validateLimit(
      limit,
      maximum: AssistantPolicy.maximumPendingReplayBatchSize,
    );
    final cursorCreatedAtEpochMs = afterCreatedAt
        ?.toUtc()
        .millisecondsSinceEpoch;
    final cursorClientMessageId = afterClientMessageId == null
        ? null
        : RoamlyValueGuards.requireUuid(
            afterClientMessageId,
            field: 'afterClientMessageId',
          );
    final query = _database.select(_database.assistantPendingRequests)
      ..where((row) {
        final ownerPredicate = row.ownerId.equals(_ownerId);
        if (cursorCreatedAtEpochMs == null || cursorClientMessageId == null) {
          return ownerPredicate;
        }
        final afterCursor =
            row.createdAtEpochMs.isBiggerThanValue(cursorCreatedAtEpochMs) |
            (row.createdAtEpochMs.equals(cursorCreatedAtEpochMs) &
                row.clientMessageId.isBiggerThanValue(cursorClientMessageId));
        return ownerPredicate & afterCursor;
      })
      ..orderBy([
        (row) => OrderingTerm.asc(row.createdAtEpochMs),
        (row) => OrderingTerm.asc(row.clientMessageId),
      ])..limit(limit);

    final records = await query.get();
    return records.map(_requestFromRecord).toList(growable: false);
  }

  @override
  Future<AssistantRequest?> getPendingRequest({
    required String clientMessageId,
  }) async {
    final validatedClientMessageId = RoamlyValueGuards.requireUuid(
      clientMessageId,
      field: 'clientMessageId',
    );
    final query = _database.select(_database.assistantPendingRequests)
      ..where(
        (row) =>
            row.ownerId.equals(_ownerId) &
            row.clientMessageId.equals(validatedClientMessageId),
      );
    final record = await query.getSingleOrNull();
    return record == null ? null : _requestFromRecord(record);
  }

  @override
  Future<void> deletePendingRequest({required String clientMessageId}) async {
    final validatedClientMessageId = RoamlyValueGuards.requireUuid(
      clientMessageId,
      field: 'clientMessageId',
    );
    await (_database.delete(_database.assistantPendingRequests)..where(
          (row) =>
              row.ownerId.equals(_ownerId) &
              row.clientMessageId.equals(validatedClientMessageId),
        ))
        .go();
  }

  @override
  Future<void> updateMessageDeliveryState({
    required String messageId,
    required AssistantMessageDeliveryState deliveryState,
    required DateTime updatedAt,
  }) {
    final validatedMessageId = RoamlyValueGuards.requireUuid(
      messageId,
      field: 'messageId',
    );

    final normalizedUpdatedAt = RoamlyValueNormalizers.utc(updatedAt);

    return _database.transaction(() async {
      final query = _database.select(_database.assistantMessages)
        ..where(
          (row) =>
              row.ownerId.equals(_ownerId) & row.id.equals(validatedMessageId),
        );

      final existingRecord = await query.getSingleOrNull();

      if (existingRecord == null) {
        throw StateError('The assistant message does not exist.');
      }

      final updatedAtEpochMs = normalizedUpdatedAt.millisecondsSinceEpoch;

      if (updatedAtEpochMs < existingRecord.createdAtEpochMs) {
        throw ArgumentError('updatedAt cannot be before message createdAt.');
      }

      // Ignore stale delivery events received after a newer event.
      if (updatedAtEpochMs < existingRecord.updatedAtEpochMs) {
        return;
      }

      await (_database.update(_database.assistantMessages)..where(
            (row) =>
                row.ownerId.equals(_ownerId) &
                row.id.equals(validatedMessageId),
          ))
          .write(
            AssistantMessagesCompanion(
              deliveryState: Value(deliveryState),
              updatedAtEpochMs: Value(updatedAtEpochMs),
            ),
          );
    });
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

    // Related messages are deleted through ON DELETE CASCADE.
  }

  @override
  Future<void> clear() {
    return _database.transaction(() async {
      // Explicit deletion protects cleanup if an old database was opened
      // before foreign-key enforcement was enabled.
      await (_database.delete(
        _database.assistantPendingRequests,
      )..where((row) => row.ownerId.equals(_ownerId))).go();

      await (_database.delete(
        _database.assistantMessages,
      )..where((row) => row.ownerId.equals(_ownerId))).go();

      await (_database.delete(
        _database.assistantConversations,
      )..where((row) => row.ownerId.equals(_ownerId))).go();
    });
  }

  Future<void> _upsertConversationRecord(
    AssistantConversation conversation,
  ) async {
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

  Future<void> _upsertMessageRecord(AssistantMessage message) async {
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

  Future<void> _upsertPendingRequestRecord(AssistantRequest request) async {
    await _database
        .into(_database.assistantPendingRequests)
        .insertOnConflictUpdate(
          AssistantPendingRequestsCompanion.insert(
            ownerId: _ownerId,
            clientMessageId: request.clientMessageId,
            conversationLocalId: request.conversationLocalId,
            conversationId: Value(request.conversationId),
            tripId: Value(request.tripId),
            message: request.message,
            locale: request.locale,
            createdAtEpochMs: request.createdAt.millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> _ensureConversationBelongsToOwner(String localId) async {
    final storedOwnerId = await _findConversationOwnerId(localId);

    if (storedOwnerId == null) {
      throw StateError('The parent assistant conversation does not exist.');
    }

    if (storedOwnerId != _ownerId) {
      throw StateError('The assistant conversation belongs to another user.');
    }
  }

  Future<void> _ensureConversationRecordOwnership(String localId) async {
    final storedOwnerId = await _findConversationOwnerId(localId);

    if (storedOwnerId != null && storedOwnerId != _ownerId) {
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

  Future<String?> _findConversationOwnerId(String localId) async {
    final query = _database.selectOnly(_database.assistantConversations)
      ..addColumns([_database.assistantConversations.ownerId])
      ..where(_database.assistantConversations.localId.equals(localId));

    final record = await query.getSingleOrNull();

    return record?.read(_database.assistantConversations.ownerId);
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

  static AssistantRequest _requestFromRecord(
    AssistantPendingRequestRecord record,
  ) {
    return AssistantRequest(
      conversationLocalId: record.conversationLocalId,
      clientMessageId: record.clientMessageId,
      conversationId: record.conversationId,
      tripId: record.tripId,
      message: record.message,
      locale: record.locale,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        record.createdAtEpochMs,
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

  @override
  Future<AssistantMessage?> getUserMessageByClientMessageId({
    required String clientMessageId,
  }) async {
    final validatedClientMessageId = RoamlyValueGuards.requireUuid(
      clientMessageId,
      field: 'clientMessageId',
    );

    final query = _database.select(_database.assistantMessages)
      ..where(
        (row) =>
            row.ownerId.equals(_ownerId) &
            row.clientMessageId.equals(validatedClientMessageId) &
            row.author.equals(AssistantMessageAuthor.user.name),
      )
      ..limit(2);

    final records = await query.get();

    if (records.length > 1) {
      throw StateError(
        'Multiple user messages have the same client message ID.',
      );
    }

    return records.isEmpty ? null : _messageFromRecord(records.single);
  }
}
