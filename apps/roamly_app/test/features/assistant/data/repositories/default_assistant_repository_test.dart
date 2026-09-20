import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/data/database/assistant_database.dart';
import 'package:roamly_app/src/features/assistant/data/models/assistant_incoming_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_pong_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_accepted_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/repositories/default_assistant_repository.dart';
import 'package:roamly_app/src/features/assistant/data/services/assistant_realtime_session.dart';
import 'package:roamly_app/src/features/assistant/data/sources/drift_assistant_local_data_source.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_conversation.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_event.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message_delivery_state.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_request.dart';

const _clientMessageId = '00000000-0000-4000-8000-000000000001';
const _conversationId = '00000000-0000-4000-8000-000000000002';
const _localConversationId = '00000000-0000-4000-8000-000000000004';
const _tripId = '00000000-0000-4000-8000-000000000003';
const _messageId1 = '00000000-0000-4000-8000-000000000005';
const _messageId2 = '00000000-0000-4000-8000-000000000006';
const _messageId3 = '00000000-0000-4000-8000-000000000007';
const _clientMessageId2 = '00000000-0000-4000-8000-000000000008';
const _clientMessageId3 = '00000000-0000-4000-8000-000000000009';
const _sentAtText = '2026-09-18T13:00:00+05:00';
final _occurredAt = DateTime.parse(_sentAtText).toUtc();

Map<String, Object?> _event({
  required String type,
  required Map<String, Object?> payload,
}) {
  return <String, Object?>{
    'version': 1,
    'type': type,
    'sent_at': _sentAtText,
    'payload': payload,
  };
}

final class _FakeRealtimeSession implements AssistantRealtimeSession {
  final eventController =
      StreamController<AssistantIncomingEventModel>.broadcast();
  final readinessController = StreamController<bool>.broadcast();
  final sentRequests = <TravelRequestEventModel>[];

  int connectCalls = 0;
  int disconnectCalls = 0;
  int disposeCalls = 0;
  Object? sendError;

  @override
  bool isReady = false;

  @override
  Stream<AssistantIncomingEventModel> get events => eventController.stream;

  @override
  Stream<bool> get readinessChanges => readinessController.stream;

  @override
  void connect() {
    connectCalls++;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
  }

  @override
  Future<void> sendTravelRequest(TravelRequestEventModel request) async {
    sentRequests.add(request);

    final error = sendError;
    if (error != null) throw error;
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }

  Future<void> closeControllers() async {
    await Future.wait<dynamic>([
      eventController.close(),
      readinessController.close(),
    ]);
  }
}

void main() {
  late AssistantDatabase database;
  late DriftAssistantLocalDataSource localDataSource;
  late _FakeRealtimeSession session;
  late DefaultAssistantRepository repository;

  setUp(() {
    database = AssistantDatabase(NativeDatabase.memory());
    localDataSource = DriftAssistantLocalDataSource(
      database: database,
      ownerId: 'repository-test-user',
    );
    session = _FakeRealtimeSession();
    repository = DefaultAssistantRepository(
      realtimeSession: session,
      localDataSource: localDataSource,
    );
  });

  tearDown(() async {
    await session.closeControllers();
    await database.close();
  });

  test(
    'filters connection events and publishes mapped domain events',
    () async {
      final nextEvent = repository.events.first;

      session.eventController.add(
        ConnectionPongEventModel.fromJson(
          _event(type: 'connection.pong', payload: <String, Object?>{}),
        ),
      );
      session.eventController.add(
        TravelRequestAcceptedEventModel.fromJson(
          _event(
            type: 'travel.request.accepted',
            payload: <String, Object?>{
              'client_message_id': _clientMessageId,
              'conversation_id': _conversationId,
            },
          ),
        ),
      );

      expect(
        await nextEvent,
        AssistantRequestAccepted(
          occurredAt: _occurredAt,
          clientMessageId: _clientMessageId,
          conversationId: _conversationId,
        ),
      );
      expect(identical(repository.events, repository.events), isTrue);
    },
  );

  test('delegates connection lifecycle and readiness state', () async {
    session.isReady = true;
    final nextReadiness = repository.readinessChanges.first;

    repository.connect();
    await repository.disconnect();
    session.readinessController.add(true);

    expect(repository.isReady, isTrue);
    expect(await nextReadiness, isTrue);
    expect(session.connectCalls, 1);
    expect(session.disconnectCalls, 1);

    await repository.dispose();
    expect(session.disposeCalls, 1);
  });

  test('maps every request field to the transport model', () async {
    final request = AssistantRequest(
      clientMessageId: _clientMessageId,
      conversationId: _conversationId,
      conversationLocalId: _localConversationId,
      tripId: _tripId,
      message: 'Plan Lahore',
      locale: 'en-PK',
      createdAt: DateTime.parse(_sentAtText),
    );

    await repository.sendRequest(request);

    expect(session.sentRequests, hasLength(1));
    final model = session.sentRequests.single;
    expect(model.clientMessageId, request.clientMessageId);
    expect(model.conversationId, request.conversationId);
    expect(model.tripId, request.tripId);
    expect(model.message, request.message);
    expect(model.locale, request.locale);
    expect(model.sentAt, request.createdAt);
  });

  test('preserves transport send failures', () async {
    final failure = StateError('socket is not ready');
    session.sendError = failure;
    final request = AssistantRequest(
      clientMessageId: _clientMessageId,
      conversationLocalId: _localConversationId,
      message: 'Plan Lahore',
      createdAt: DateTime.parse(_sentAtText),
    );

    await expectLater(repository.sendRequest(request), throwsA(same(failure)));
    expect(session.sentRequests, hasLength(1));
  });

  test('preserves errors from the realtime event stream', () async {
    final failure = StateError('stream failed');
    final nextEvent = repository.events.first;

    session.eventController.addError(failure);

    await expectLater(nextEvent, throwsA(same(failure)));
  });

  test('exposes cached history and forwards pagination', () async {
    final conversation = _conversation();
    final first = _message(
      id: _messageId1,
      clientMessageId: _clientMessageId,
      createdAt: _historyTime(1),
    );
    final second = _message(
      id: _messageId2,
      clientMessageId: _clientMessageId2,
      createdAt: _historyTime(2),
    );
    final third = _message(
      id: _messageId3,
      clientMessageId: _clientMessageId3,
      createdAt: _historyTime(3),
    );

    await localDataSource.upsertConversationWithMessages(
      conversation: conversation,
      messages: [first, second, third],
    );

    expect(await repository.watchConversations().first, [conversation]);
    expect(
      await repository
          .watchMessages(conversationLocalId: conversation.localId)
          .first,
      [first, second, third],
    );

    final previousPage = await repository.getMessagesBefore(
      conversationLocalId: conversation.localId,
      beforeCreatedAt: third.createdAt,
      beforeId: third.id,
      limit: 1,
    );

    expect(previousPage, [second]);
  });

  test('deletes a conversation and clears cached history', () async {
    final conversation = _conversation();

    await localDataSource.upsertConversation(conversation);
    await repository.deleteConversation(localId: conversation.localId);

    expect(
      await localDataSource.getConversation(localId: conversation.localId),
      isNull,
    );

    await localDataSource.upsertConversation(conversation);
    await repository.clearLocalHistory();

    expect(await repository.watchConversations().first, isEmpty);
  });
}

AssistantConversation _conversation() {
  return AssistantConversation(
    localId: _localConversationId,
    remoteId: _conversationId,
    title: 'Repository test trip',
    createdAt: _historyTime(0),
    updatedAt: _historyTime(0),
  );
}

AssistantMessage _message({
  required String id,
  required String clientMessageId,
  required DateTime createdAt,
}) {
  return AssistantMessage(
    id: id,
    conversationLocalId: _localConversationId,
    clientMessageId: clientMessageId,
    author: AssistantMessageAuthor.user,
    content: 'Plan Lahore',
    deliveryState: AssistantMessageDeliveryState.pending,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

DateTime _historyTime(int minute) {
  return DateTime.utc(2026, 9, 18, 8, minute);
}
