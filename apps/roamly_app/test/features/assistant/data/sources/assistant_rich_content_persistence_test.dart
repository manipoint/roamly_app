import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/data/database/assistant_database.dart';
import 'package:roamly_app/src/features/assistant/data/sources/drift_assistant_local_data_source.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_conversation.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message_delivery_state.dart';

import '../../fixtures/assistant_rich_content_fixture.dart';

const _conversationId = '10000000-0000-4000-8000-000000000001';
const _messageId = '10000000-0000-4000-8000-000000000002';
const _otherMessageId = '10000000-0000-4000-8000-000000000003';
const _clientId = '10000000-0000-4000-8000-000000000004';
final _createdAt = DateTime.utc(2026, 10, 1);

AssistantMessage _message({
  String id = _messageId,
  bool withRichContent = true,
}) {
  return AssistantMessage(
    id: id,
    conversationLocalId: _conversationId,
    clientMessageId: _clientId,
    assistantMessageId: id,
    author: AssistantMessageAuthor.assistant,
    content: 'Your Japan suggestions are ready.',
    richContent: withRichContent ? richContentFixture() : null,
    deliveryState: AssistantMessageDeliveryState.completed,
    createdAt: _createdAt,
    updatedAt: _createdAt,
  );
}

void main() {
  late Directory directory;
  late File file;
  late AssistantDatabase database;
  late DriftAssistantLocalDataSource source;

  void openDatabase() {
    database = AssistantDatabase(NativeDatabase(file));
    source = DriftAssistantLocalDataSource(
      database: database,
      ownerId: 'user-a',
    );
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('roamly-rich-test-');
    file = File('${directory.path}/assistant.sqlite');
    openDatabase();
    await source.upsertConversation(
      AssistantConversation(
        localId: _conversationId,
        createdAt: _createdAt,
        updatedAt: _createdAt,
      ),
    );
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('schema 3 history migrates with an unknown failure reason', () async {
    await source.upsertMessage(_message());
    await database.customStatement(
      'ALTER TABLE assistant_messages DROP COLUMN failure_code',
    );
    await database.customStatement('PRAGMA user_version = 3');
    await database.close();
    openDatabase();
    final messages = await source
        .watchMessages(conversationLocalId: _conversationId)
        .first;
    expect(messages.single, _message());
    expect(messages.single.failureCode, isNull);
    final version = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.read<int>('user_version'), 4);
  });

  test('failure reason survives closing and reopening SQLite', () async {
    final original = AssistantMessage(
      id: _messageId,
      conversationLocalId: _conversationId,
      clientMessageId: _clientId,
      author: AssistantMessageAuthor.user,
      content: 'UK',
      deliveryState: AssistantMessageDeliveryState.failed,
      failureCode: 'response.providerError',
      createdAt: _createdAt,
      updatedAt: _createdAt,
    );
    await source.upsertMessage(original);
    await database.close();
    openDatabase();
    final restored = await source.getUserMessageByClientMessageId(
      clientMessageId: _clientId,
    );
    expect(restored, original);
    expect(restored?.failureCode, 'response.providerError');
  });

  test(
    'restores complete rich content after closing and reopening SQLite',
    () async {
      final original = _message();
      await source.upsertMessage(original);
      final row = await database.select(database.assistantMessages).getSingle();
      expect(row.richContentJson, isNotNull);

      await database.close();
      openDatabase();

      final messages = await source
          .watchMessages(conversationLocalId: _conversationId)
          .first;
      expect(messages, [original]);
      expect(messages.single.richContent!.sections, hasLength(3));

      final olderMessages = await source.getMessagesBefore(
        conversationLocalId: _conversationId,
        beforeCreatedAt: _createdAt.add(const Duration(days: 1)),
        beforeId: _otherMessageId,
      );
      expect(olderMessages, [original]);
    },
  );

  test(
    'corrupt rich content preserves text and other messages on both read paths',
    () async {
      final healthy = _message(id: _otherMessageId);
      await source.upsertMessage(_message());
      await source.upsertMessage(healthy);

      for (final invalid in [
        '{broken',
        '[]',
        '{"type":"rich_response","schema_version":1,"sections":[]}',
      ]) {
        await database.customStatement(
          'UPDATE assistant_messages SET rich_content_json = ? WHERE id = ?',
          [invalid, _messageId],
        );
        final watched = await source
            .watchMessages(conversationLocalId: _conversationId)
            .first;
        final paged = await source.getMessagesBefore(
          conversationLocalId: _conversationId,
          beforeCreatedAt: _createdAt.add(const Duration(days: 1)),
          beforeId: _otherMessageId,
        );
        for (final messages in [watched, paged]) {
          expect(messages, hasLength(2));
          expect(
            messages.singleWhere((m) => m.id == _messageId),
            _message(withRichContent: false),
          );
          expect(messages.singleWhere((m) => m.id == _otherMessageId), healthy);
        }
      }
    },
  );

  test('text-only messages retain a null JSON column', () async {
    final original = _message(withRichContent: false);
    await source.upsertMessage(original);
    final row = await database.select(database.assistantMessages).getSingle();
    expect(row.richContentJson, isNull);
    expect(
      await source.watchMessages(conversationLocalId: _conversationId).first,
      [original],
    );
  });

  test(
    'another owner cannot read or overwrite persisted rich content',
    () async {
      final original = _message();
      await source.upsertMessage(original);
      final otherOwner = DriftAssistantLocalDataSource(
        database: database,
        ownerId: 'user-b',
      );
      expect(
        await otherOwner
            .watchMessages(conversationLocalId: _conversationId)
            .first,
        isEmpty,
      );
      expect(
        await otherOwner.getMessagesBefore(
          conversationLocalId: _conversationId,
          beforeCreatedAt: _createdAt.add(const Duration(days: 1)),
          beforeId: _otherMessageId,
        ),
        isEmpty,
      );
      await expectLater(otherOwner.upsertMessage(original), throwsStateError);
      expect(
        await source.watchMessages(conversationLocalId: _conversationId).first,
        [original],
      );
    },
  );
}
