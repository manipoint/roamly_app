import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/data/database/assistant_database.dart';
import 'package:roamly_app/src/features/assistant/data/sources/drift_assistant_local_data_source.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_conversation.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message_delivery_state.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_request.dart';

void main() {
  late AssistantDatabase database;
  late DriftAssistantLocalDataSource dataSource;

  setUp(() {
    database = AssistantDatabase(NativeDatabase.memory());

    dataSource = DriftAssistantLocalDataSource(
      database: database,
      ownerId: 'user-a',
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('DriftAssistantLocalDataSource', () {
    test('rejects a blank owner ID', () {
      expect(
        () => DriftAssistantLocalDataSource(database: database, ownerId: '   '),
        throwsArgumentError,
      );
    });

    test('stores and retrieves a conversation', () async {
      final conversation = _conversation();

      await dataSource.upsertConversation(conversation);

      final byLocalId = await dataSource.getConversation(
        localId: conversation.localId,
      );

      final byRemoteId = await dataSource.getConversationByRemoteId(
        remoteId: conversation.remoteId!,
      );

      expect(byLocalId, conversation);
      expect(byRemoteId, conversation);
    });

    test('finds the active user message by client message ID', () async {
      final conversation = _conversation();
      final message = _userMessage(
        id: _messageId1,
        clientMessageId: _clientMessageId1,
        conversationLocalId: conversation.localId,
        createdAt: _time(1),
      );

      await dataSource.upsertConversationWithMessages(
        conversation: conversation,
        messages: [message],
      );

      final storedMessage = await dataSource.getUserMessageByClientMessageId(
        clientMessageId: message.clientMessageId,
      );

      expect(storedMessage, message);
    });

    test('atomically stores and removes a durable pending request', () async {
      final conversation = _conversation();
      final createdAt = _time(1).add(const Duration(microseconds: 456));
      final request = AssistantRequest(
        conversationLocalId: conversation.localId,
        clientMessageId: _clientMessageId1,
        conversationId: conversation.remoteId,
        tripId: _tripId,
        message: 'Create a travel plan',
        locale: 'en-PK',
        createdAt: createdAt,
      );
      final message = _userMessage(
        id: request.clientMessageId,
        clientMessageId: request.clientMessageId,
        conversationLocalId: conversation.localId,
        createdAt: createdAt,
      );

      await dataSource.cachePendingRequest(
        conversation: conversation,
        message: message,
        request: request,
      );

      final pendingRequests = await dataSource.getPendingRequests();
      expect(pendingRequests, hasLength(1));
      expect(pendingRequests.single.clientMessageId, request.clientMessageId);
      expect(pendingRequests.single.conversationId, request.conversationId);
      expect(pendingRequests.single.tripId, request.tripId);
      expect(pendingRequests.single.message, request.message);
      expect(pendingRequests.single.locale, request.locale);
      expect(
        pendingRequests.single.createdAt.millisecondsSinceEpoch,
        request.createdAt.millisecondsSinceEpoch,
      );

      await dataSource.deletePendingRequest(
        clientMessageId: request.clientMessageId,
      );

      expect(await dataSource.getPendingRequests(), isEmpty);
      expect(
        await dataSource.getUserMessageByClientMessageId(
          clientMessageId: request.clientMessageId,
        ),
        isNotNull,
      );
    });

    test(
      'paginates pending requests with a stable keyset after deletion',
      () async {
        final conversation = _conversation();
        final createdAt = _time(1);
        final requests = [
          _pendingRequest(
            conversation: conversation,
            clientMessageId: _clientMessageId3,
            createdAt: createdAt,
          ),
          _pendingRequest(
            conversation: conversation,
            clientMessageId: _clientMessageId1,
            createdAt: createdAt,
          ),
          _pendingRequest(
            conversation: conversation,
            clientMessageId: _clientMessageId2,
            createdAt: createdAt,
          ),
        ];

        for (final request in requests) {
          await dataSource.cachePendingRequest(
            conversation: conversation,
            message: _userMessage(
              id: request.clientMessageId,
              clientMessageId: request.clientMessageId,
              conversationLocalId: conversation.localId,
              createdAt: request.createdAt,
            ),
            request: request,
          );
        }

        final firstPage = await dataSource.getPendingRequests(limit: 2);

        expect(firstPage.map((request) => request.clientMessageId), [
          _clientMessageId1,
          _clientMessageId2,
        ]);

        final cursor = firstPage.last;
        await dataSource.deletePendingRequest(
          clientMessageId: cursor.clientMessageId,
        );

        final secondPage = await dataSource.getPendingRequests(
          limit: 2,
          afterCreatedAt: cursor.createdAt,
          afterClientMessageId: cursor.clientMessageId,
        );

        expect(secondPage.map((request) => request.clientMessageId), [
          _clientMessageId3,
        ]);
      },
    );

    test('does not expose another user message by client message ID', () async {
      final userBDataSource = DriftAssistantLocalDataSource(
        database: database,
        ownerId: 'user-b',
      );
      final userBConversation = _conversation(
        localId: _conversationId2,
        remoteId: _remoteConversationId2,
      );
      final userBMessage = _userMessage(
        id: _messageId2,
        clientMessageId: _clientMessageId2,
        conversationLocalId: userBConversation.localId,
        createdAt: _time(1),
      );

      await userBDataSource.upsertConversationWithMessages(
        conversation: userBConversation,
        messages: [userBMessage],
      );

      final userAMessage = await dataSource.getUserMessageByClientMessageId(
        clientMessageId: userBMessage.clientMessageId,
      );

      expect(userAMessage, isNull);
    });

    test(
      'watches messages in chronological order and preserves timestamps',
      () async {
        final conversation = _conversation();

        final laterMessage = _userMessage(
          id: _messageId3,
          clientMessageId: _clientMessageId3,
          conversationLocalId: conversation.localId,
          createdAt: _time(3),
        );

        final earlierMessage = _userMessage(
          id: _messageId1,
          clientMessageId: _clientMessageId1,
          conversationLocalId: conversation.localId,
          createdAt: _time(1),
        );

        await dataSource.upsertConversationWithMessages(
          conversation: conversation,
          messages: [laterMessage, earlierMessage],
        );

        final messages = await dataSource
            .watchMessages(conversationLocalId: conversation.localId)
            .first;

        expect(messages.map((message) => message.id), [
          earlierMessage.id,
          laterMessage.id,
        ]);

        expect(messages.first.createdAt, earlierMessage.createdAt);

        expect(messages.last.createdAt, laterMessage.createdAt);
      },
    );

    test('uses stable keyset pagination for equal timestamps', () async {
      final conversation = _conversation();
      final sameCreatedAt = _time(1);

      final first = _userMessage(
        id: _messageId1,
        clientMessageId: _clientMessageId1,
        conversationLocalId: conversation.localId,
        createdAt: sameCreatedAt,
      );

      final second = _userMessage(
        id: _messageId2,
        clientMessageId: _clientMessageId2,
        conversationLocalId: conversation.localId,
        createdAt: sameCreatedAt,
      );

      final third = _userMessage(
        id: _messageId3,
        clientMessageId: _clientMessageId3,
        conversationLocalId: conversation.localId,
        createdAt: sameCreatedAt,
      );

      await dataSource.upsertConversationWithMessages(
        conversation: conversation,
        messages: [first, second, third],
      );

      final olderMessages = await dataSource.getMessagesBefore(
        conversationLocalId: conversation.localId,
        beforeCreatedAt: third.createdAt,
        beforeId: third.id,
      );

      expect(olderMessages.map((message) => message.id), [first.id, second.id]);
    });

    test('updates delivery state and ignores stale updates', () async {
      final conversation = _conversation();

      final message = _userMessage(
        id: _messageId1,
        clientMessageId: _clientMessageId1,
        conversationLocalId: conversation.localId,
        createdAt: _time(1),
      );

      await dataSource.upsertConversationWithMessages(
        conversation: conversation,
        messages: [message],
      );

      await dataSource.updateMessageDeliveryState(
        messageId: message.id,
        deliveryState: AssistantMessageDeliveryState.processing,
        updatedAt: _time(3),
      );

      await dataSource.updateMessageDeliveryState(
        messageId: message.id,
        deliveryState: AssistantMessageDeliveryState.failed,
        updatedAt: _time(2),
      );

      final messages = await dataSource
          .watchMessages(conversationLocalId: conversation.localId)
          .first;

      expect(messages, hasLength(1));

      expect(
        messages.single.deliveryState,
        AssistantMessageDeliveryState.processing,
      );

      expect(messages.single.updatedAt, _time(3));
    });

    test('prevents one user from overwriting another user message', () async {
      final userBDataSource = DriftAssistantLocalDataSource(
        database: database,
        ownerId: 'user-b',
      );

      final userBConversation = _conversation(
        localId: _conversationId2,
        remoteId: _remoteConversationId2,
      );

      final userBMessage = _userMessage(
        id: _messageId1,
        clientMessageId: _clientMessageId1,
        conversationLocalId: userBConversation.localId,
        createdAt: _time(1),
      );

      await userBDataSource.upsertConversationWithMessages(
        conversation: userBConversation,
        messages: [userBMessage],
      );

      final userAConversation = _conversation();

      await dataSource.upsertConversation(userAConversation);

      final conflictingMessage = _userMessage(
        id: userBMessage.id,
        clientMessageId: _clientMessageId2,
        conversationLocalId: userAConversation.localId,
        createdAt: _time(2),
      );

      await expectLater(
        dataSource.upsertMessage(conflictingMessage),
        throwsA(isA<StateError>()),
      );

      final userBMessages = await userBDataSource
          .watchMessages(conversationLocalId: userBConversation.localId)
          .first;

      expect(userBMessages, [userBMessage]);
    });

    test('clear removes only the active user history', () async {
      final userBDataSource = DriftAssistantLocalDataSource(
        database: database,
        ownerId: 'user-b',
      );

      final userAConversation = _conversation();

      final userBConversation = _conversation(
        localId: _conversationId2,
        remoteId: _remoteConversationId2,
      );

      await dataSource.upsertConversationWithMessages(
        conversation: userAConversation,
        messages: [
          _userMessage(
            id: _messageId1,
            clientMessageId: _clientMessageId1,
            conversationLocalId: userAConversation.localId,
            createdAt: _time(1),
          ),
        ],
      );

      await userBDataSource.upsertConversationWithMessages(
        conversation: userBConversation,
        messages: [
          _userMessage(
            id: _messageId2,
            clientMessageId: _clientMessageId2,
            conversationLocalId: userBConversation.localId,
            createdAt: _time(1),
          ),
        ],
      );

      await dataSource.clear();

      final userAConversations = await dataSource.watchConversations().first;

      final userBConversations = await userBDataSource
          .watchConversations()
          .first;

      expect(userAConversations, isEmpty);
      expect(userBConversations, [userBConversation]);
    });

    test('deleting a conversation cascades to its messages', () async {
      final conversation = _conversation();

      await dataSource.upsertConversationWithMessages(
        conversation: conversation,
        messages: [
          _userMessage(
            id: _messageId1,
            clientMessageId: _clientMessageId1,
            conversationLocalId: conversation.localId,
            createdAt: _time(1),
          ),
        ],
      );

      await dataSource.deleteConversation(localId: conversation.localId);

      final storedConversation = await dataSource.getConversation(
        localId: conversation.localId,
      );

      final messages = await dataSource
          .watchMessages(conversationLocalId: conversation.localId)
          .first;

      expect(storedConversation, isNull);
      expect(messages, isEmpty);
    });
  });
}

AssistantConversation _conversation({
  String localId = _conversationId1,
  String remoteId = _remoteConversationId1,
}) {
  return AssistantConversation(
    localId: localId,
    remoteId: remoteId,
    title: 'Europe trip',
    createdAt: _time(0),
    updatedAt: _time(0),
  );
}

AssistantMessage _userMessage({
  required String id,
  required String clientMessageId,
  required String conversationLocalId,
  required DateTime createdAt,
}) {
  return AssistantMessage(
    id: id,
    conversationLocalId: conversationLocalId,
    clientMessageId: clientMessageId,
    author: AssistantMessageAuthor.user,
    content: 'Create a travel plan',
    deliveryState: AssistantMessageDeliveryState.pending,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

AssistantRequest _pendingRequest({
  required AssistantConversation conversation,
  required String clientMessageId,
  required DateTime createdAt,
}) {
  return AssistantRequest(
    conversationLocalId: conversation.localId,
    clientMessageId: clientMessageId,
    conversationId: conversation.remoteId,
    message: 'Create a travel plan',
    createdAt: createdAt,
  );
}

DateTime _time(int minute) {
  return DateTime.utc(2026, 1, 1, 12, minute);
}

const _conversationId1 = '10000000-0000-4000-8000-000000000001';
const _conversationId2 = '10000000-0000-4000-8000-000000000002';

const _remoteConversationId1 = '20000000-0000-4000-8000-000000000001';
const _remoteConversationId2 = '20000000-0000-4000-8000-000000000002';

const _messageId1 = '30000000-0000-4000-8000-000000000001';
const _messageId2 = '30000000-0000-4000-8000-000000000002';
const _messageId3 = '30000000-0000-4000-8000-000000000003';

const _clientMessageId1 = '40000000-0000-4000-8000-000000000001';
const _clientMessageId2 = '40000000-0000-4000-8000-000000000002';
const _clientMessageId3 = '40000000-0000-4000-8000-000000000003';
const _tripId = '50000000-0000-4000-8000-000000000001';
