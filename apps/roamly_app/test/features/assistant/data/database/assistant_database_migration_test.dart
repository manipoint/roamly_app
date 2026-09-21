import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/data/database/assistant_database.dart';

void main() {
  test('migrates schema 1 history and creates the pending outbox', () async {
    final executor = NativeDatabase.memory(
      setup: (database) {
        database
          ..execute('''
            CREATE TABLE assistant_conversations (
              owner_id TEXT NOT NULL,
              local_id TEXT NOT NULL PRIMARY KEY,
              remote_id TEXT NULL,
              title TEXT NULL,
              created_at_epoch_ms INTEGER NOT NULL,
              updated_at_epoch_ms INTEGER NOT NULL
            )
          ''')
          ..execute('''
            CREATE TABLE assistant_messages (
              owner_id TEXT NOT NULL,
              id TEXT NOT NULL PRIMARY KEY,
              conversation_local_id TEXT NOT NULL REFERENCES
                assistant_conversations (local_id) ON DELETE CASCADE,
              client_message_id TEXT NOT NULL,
              assistant_message_id TEXT NULL,
              itinerary_id TEXT NULL,
              author TEXT NOT NULL,
              content TEXT NOT NULL,
              delivery_state TEXT NOT NULL,
              created_at_epoch_ms INTEGER NOT NULL,
              updated_at_epoch_ms INTEGER NOT NULL
            )
          ''')
          ..execute('''
            INSERT INTO assistant_conversations (
              owner_id,
              local_id,
              title,
              created_at_epoch_ms,
              updated_at_epoch_ms
            ) VALUES (
              'migration-user',
              '10000000-0000-4000-8000-000000000001',
              'Existing conversation',
              1,
              1
            )
          ''')
          ..execute('PRAGMA user_version = 1');
      },
    );
    final database = AssistantDatabase(executor);
    addTearDown(database.close);

    final version = await database
        .customSelect('PRAGMA user_version')
        .map((row) => row.read<int>('user_version'))
        .getSingle();
    final existingHistory = await database
        .customSelect('SELECT title FROM assistant_conversations')
        .map((row) => row.read<String>('title'))
        .getSingle();
    final pendingTable = await database
        .customSelect(
          "SELECT name FROM sqlite_master "
          "WHERE type = 'table' AND name = 'assistant_pending_requests'",
        )
        .map((row) => row.read<String>('name'))
        .getSingle();
    final pendingIndex = await database
        .customSelect(
          "SELECT name FROM sqlite_master "
          "WHERE type = 'index' "
          "AND name = 'assistant_pending_requests_owner_created_at'",
        )
        .map((row) => row.read<String>('name'))
        .getSingle();

    expect(version, 2);
    expect(existingHistory, 'Existing conversation');
    expect(pendingTable, 'assistant_pending_requests');
    expect(pendingIndex, 'assistant_pending_requests_owner_created_at');
  });
}
