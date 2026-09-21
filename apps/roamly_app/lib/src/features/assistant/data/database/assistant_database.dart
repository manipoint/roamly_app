import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/entities/assistant_message.dart';
import '../../domain/entities/assistant_message_delivery_state.dart';

part 'assistant_database.g.dart';

@DataClassName('AssistantConversationRecord')
@TableIndex(
  name: 'assistant_conversations_owner_updated_at',
  columns: {#ownerId, #updatedAtEpochMs},
)
@TableIndex(
  name: 'assistant_conversations_owner_remote_id',
  columns: {#ownerId, #remoteId},
  unique: true,
)
class AssistantConversations extends Table {
  TextColumn get ownerId => text()();
  TextColumn get localId => text()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get title => text().nullable()();
  IntColumn get createdAtEpochMs => integer()();
  IntColumn get updatedAtEpochMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

@DataClassName('AssistantMessageRecord')
@TableIndex(
  name: 'assistant_messages_owner_conversation_created_at',
  columns: {#ownerId, #conversationLocalId, #createdAtEpochMs, #id},
)
@TableIndex(
  name: 'assistant_messages_owner_client_message_id',
  columns: {#ownerId, #clientMessageId},
)
@TableIndex(
  name: 'assistant_messages_owner_assistant_message_id',
  columns: {#ownerId, #assistantMessageId},
  unique: true,
)
class AssistantMessages extends Table {
  TextColumn get ownerId => text()();
  TextColumn get id => text()();
  TextColumn get conversationLocalId => text().references(
    AssistantConversations,
    #localId,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get clientMessageId => text()();
  TextColumn get assistantMessageId => text().nullable()();
  TextColumn get itineraryId => text().nullable()();
  TextColumn get author => textEnum<AssistantMessageAuthor>()();
  TextColumn get content => text()();
  TextColumn get deliveryState => textEnum<AssistantMessageDeliveryState>()();
  IntColumn get createdAtEpochMs => integer()();
  IntColumn get updatedAtEpochMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AssistantPendingRequestRecord')
@TableIndex(
  name: 'assistant_pending_requests_owner_created_at',
  columns: {#ownerId, #createdAtEpochMs, #clientMessageId},
)
class AssistantPendingRequests extends Table {
  TextColumn get ownerId => text()();
  TextColumn get clientMessageId => text()();
  TextColumn get conversationLocalId => text().references(
    AssistantConversations,
    #localId,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get conversationId => text().nullable()();
  TextColumn get tripId => text().nullable()();
  TextColumn get message => text()();
  TextColumn get locale => text()();
  IntColumn get createdAtEpochMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {ownerId, clientMessageId};
}

@DriftDatabase(
  tables: [AssistantConversations, AssistantMessages, AssistantPendingRequests],
)
final class AssistantDatabase extends _$AssistantDatabase {
  AssistantDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'roamly'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.createTable(assistantPendingRequests);
          await m.createIndex(assistantPendingRequestsOwnerCreatedAt);
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
