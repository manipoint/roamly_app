import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_app/src/features/assistant/data/database/assistant_database.dart';
import 'package:roamly_app/src/features/assistant/data/models/assistant_incoming_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_pong_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_accepted_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_rejected_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_input_required_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_response_completed_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_response_failed_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_response_processing_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/repositories/default_assistant_repository.dart';
import 'package:roamly_app/src/features/assistant/data/services/assistant_realtime_session.dart';
import 'package:roamly_app/src/features/assistant/data/sources/assistant_local_data_source.dart';
import 'package:roamly_app/src/features/assistant/data/sources/assistant_remote_data_source.dart';
import 'package:roamly_app/src/features/assistant/data/sources/drift_assistant_local_data_source.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_conversation.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_event.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message_delivery_state.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_request.dart';
import 'package:roamly_app/src/features/assistant/domain/policies/assistant_policy.dart';
import 'package:roamly_logging/roamly_logging.dart';
import 'package:roamly_networking/roamly_networking.dart';

const _clientMessageId = '00000000-0000-4000-8000-000000000001';
const _conversationId = '00000000-0000-4000-8000-000000000002';
const _localConversationId = '00000000-0000-4000-8000-000000000004';
const _tripId = '00000000-0000-4000-8000-000000000003';
const _messageId1 = '00000000-0000-4000-8000-000000000005';
const _messageId2 = '00000000-0000-4000-8000-000000000006';
const _messageId3 = '00000000-0000-4000-8000-000000000007';
const _clientMessageId2 = '00000000-0000-4000-8000-000000000008';
const _clientMessageId3 = '00000000-0000-4000-8000-000000000009';
const _clientMessageId4 = '00000000-0000-4000-8000-000000000010';
const _differentConversationId = '00000000-0000-4000-8000-000000000011';
const _assistantMessageId = '00000000-0000-4000-8000-000000000012';
const _itineraryId = '00000000-0000-4000-8000-000000000013';
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
  Future<void> Function(TravelRequestEventModel request)? sendObserver;

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
    await sendObserver?.call(request);
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

final class _FailingAssistantLocalDataSource
    implements AssistantLocalDataSource {
  _FailingAssistantLocalDataSource(
    this.failure, {
    this.conversation,
    this.message,
  });

  final Object failure;
  final AssistantConversation? conversation;
  final AssistantMessage? message;

  @override
  Future<void> upsertMessage(AssistantMessage message) => Future.error(failure);

  @override
  Future<void> cachePendingRequest({
    required AssistantConversation conversation,
    required AssistantMessage message,
    required AssistantRequest request,
  }) {
    return Future.error(failure);
  }

  @override
  Future<AssistantConversation?> getConversation({required String localId}) {
    return Future.value(conversation);
  }

  @override
  Future<AssistantMessage?> getUserMessageByClientMessageId({
    required String clientMessageId,
  }) {
    return Future.value(message);
  }

  @override
  Future<void> upsertConversationWithMessages({
    required AssistantConversation conversation,
    required Iterable<AssistantMessage> messages,
  }) {
    return Future.error(failure);
  }

  @override
  Future<void> updateMessageDeliveryState({
    required String messageId,
    required AssistantMessageDeliveryState deliveryState,
    required DateTime updatedAt,
  }) {
    return Future.error(failure);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _RecordingLogSink implements LogSink {
  final records = <LogRecord>[];

  @override
  void write(LogRecord record) => records.add(record);
}

final class _CountingAssistantLocalDataSource
    implements AssistantLocalDataSource {
  _CountingAssistantLocalDataSource(this.delegate);

  @override
  Future<void> failPendingRequest({required String clientMessageId}) =>
      delegate.failPendingRequest(clientMessageId: clientMessageId);

  final AssistantLocalDataSource delegate;
  int conversationWithMessagesWrites = 0;
  int pendingRequestsReadCount = 0;
  void Function()? pendingRequestsReadObserver;

  @override
  Future<void> cachePendingRequest({
    required AssistantConversation conversation,
    required AssistantMessage message,
    required AssistantRequest request,
  }) {
    return delegate.cachePendingRequest(
      conversation: conversation,
      message: message,
      request: request,
    );
  }

  @override
  Future<void> clear() => delegate.clear();

  @override
  Future<void> deleteConversation({required String localId}) {
    return delegate.deleteConversation(localId: localId);
  }

  @override
  Future<void> deletePendingRequest({required String clientMessageId}) {
    return delegate.deletePendingRequest(clientMessageId: clientMessageId);
  }

  @override
  Future<AssistantConversation?> getConversation({required String localId}) {
    return delegate.getConversation(localId: localId);
  }

  @override
  Future<AssistantConversation?> getConversationByRemoteId({
    required String remoteId,
  }) {
    return delegate.getConversationByRemoteId(remoteId: remoteId);
  }

  @override
  Future<List<AssistantMessage>> getMessagesBefore({
    required String conversationLocalId,
    required DateTime beforeCreatedAt,
    required String beforeId,
    int limit = AssistantPolicy.defaultMessagesLimit,
  }) {
    return delegate.getMessagesBefore(
      conversationLocalId: conversationLocalId,
      beforeCreatedAt: beforeCreatedAt,
      beforeId: beforeId,
      limit: limit,
    );
  }

  @override
  Future<List<AssistantRequest>> getPendingRequests({
    int limit = AssistantPolicy.pendingReplayBatchSize,
    DateTime? afterCreatedAt,
    String? afterClientMessageId,
  }) async {
    pendingRequestsReadCount++;
    final requests = await delegate.getPendingRequests(
      limit: limit,
      afterCreatedAt: afterCreatedAt,
      afterClientMessageId: afterClientMessageId,
    );
    pendingRequestsReadObserver?.call();
    return requests;
  }

  @override
  Future<AssistantRequest?> getPendingRequest({
    required String clientMessageId,
  }) {
    return delegate.getPendingRequest(clientMessageId: clientMessageId);
  }

  @override
  Future<AssistantMessage?> getUserMessageByClientMessageId({
    required String clientMessageId,
  }) {
    return delegate.getUserMessageByClientMessageId(
      clientMessageId: clientMessageId,
    );
  }

  @override
  Future<void> updateMessageDeliveryState({
    required String messageId,
    required AssistantMessageDeliveryState deliveryState,
    required DateTime updatedAt,
  }) {
    return delegate.updateMessageDeliveryState(
      messageId: messageId,
      deliveryState: deliveryState,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<void> upsertConversation(AssistantConversation conversation) {
    return delegate.upsertConversation(conversation);
  }

  @override
  Future<void> upsertConversationWithMessages({
    required AssistantConversation conversation,
    required Iterable<AssistantMessage> messages,
  }) {
    conversationWithMessagesWrites++;
    return delegate.upsertConversationWithMessages(
      conversation: conversation,
      messages: messages,
    );
  }

  @override
  Future<void> upsertMessage(AssistantMessage message) {
    return delegate.upsertMessage(message);
  }

  @override
  Stream<List<AssistantConversation>> watchConversations({
    int limit = AssistantPolicy.defaultConversationsLimit,
  }) {
    return delegate.watchConversations(limit: limit);
  }

  @override
  Stream<List<AssistantMessage>> watchMessages({
    required String conversationLocalId,
    int limit = AssistantPolicy.defaultMessagesLimit,
  }) {
    return delegate.watchMessages(
      conversationLocalId: conversationLocalId,
      limit: limit,
    );
  }
}

final class _RecoveryTimer implements Timer {
  _RecoveryTimer(this.delay, this.callback);
  final Duration delay;
  final void Function() callback;
  @override
  bool isActive = true;
  @override
  int tick = 0;
  @override
  void cancel() => isActive = false;
  void fire() {
    if (!isActive) return;
    isActive = false;
    tick++;
    callback();
  }
}

final class _FakeAssistantRemoteDataSource
    implements AssistantRemoteDataSource {
  final deletedConversationIds = <String>[];
  Object? deleteError;

  @override
  Future<void> deleteConversation({required String conversationId}) async {
    final error = deleteError;
    if (error != null) throw error;
    deletedConversationIds.add(conversationId);
  }
}

final class _FakeApiRequestExecutor implements ApiRequestExecutor {
  AppFailure? failure;

  @override
  Future<Result<T>> execute<T>(Future<T> Function() request) async {
    final currentFailure = failure;
    if (currentFailure != null) return FailureResult<T>(currentFailure);
    return Success<T>(await request());
  }
}

Future<void> _eventually(bool Function() condition) async {
  for (var i = 0; i < 200; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(condition(), isTrue);
}

void main() {
  late AssistantDatabase database;
  late DriftAssistantLocalDataSource localDataSource;
  late _CountingAssistantLocalDataSource countingLocalDataSource;
  late _FakeRealtimeSession session;
  late _FakeAssistantRemoteDataSource remoteDataSource;
  late _FakeApiRequestExecutor requestExecutor;
  late DefaultAssistantRepository repository;
  late List<_RecoveryTimer> recoveryTimers;

  setUp(() {
    database = AssistantDatabase(NativeDatabase.memory());
    localDataSource = DriftAssistantLocalDataSource(
      database: database,
      ownerId: 'repository-test-user',
    );
    countingLocalDataSource = _CountingAssistantLocalDataSource(
      localDataSource,
    );
    session = _FakeRealtimeSession();
    remoteDataSource = _FakeAssistantRemoteDataSource();
    requestExecutor = _FakeApiRequestExecutor();
    recoveryTimers = [];
    repository = DefaultAssistantRepository(
      realtimeSession: session,
      remoteDataSource: remoteDataSource,
      requestExecutor: requestExecutor,
      recoveryTimerFactory: (delay, callback) {
        final timer = _RecoveryTimer(delay, callback);
        recoveryTimers.add(timer);
        return timer;
      },
      localDataSource: countingLocalDataSource,
      logger: RoamlyLogger(name: 'test.assistant', sink: const NoopLogSink()),
    );
    session.isReady = true;
  });

  tearDown(() async {
    await repository.dispose();
    await session.closeControllers();
    await database.close();
  });

  test(
    'processing request recovers without readiness events with capped backoff',
    () async {
      final request = _request(
        clientMessageId: _clientMessageId,
        createdAt: _historyTime(0),
      );
      await repository.sendRequest(request);
      final next = repository.events.first;
      session.eventController.add(
        TravelResponseProcessingEventModel.fromJson(
          _event(
            type: 'travel.response.processing',
            payload: {
              'client_message_id': _clientMessageId,
              'conversation_id': _conversationId,
            },
          ),
        ),
      );
      await next;
      for (final seconds in [5, 10, 20, 30, 30]) {
        await _eventually(() => recoveryTimers.last.isActive);
        final timer = recoveryTimers.last;
        expect(timer.delay, Duration(seconds: seconds));
        final count = session.sentRequests.length;
        timer.fire();
        await _eventually(
          () =>
              session.sentRequests.length == count + 1 &&
              recoveryTimers.last != timer,
        );
        expect(
          session.sentRequests.last.clientMessageId,
          request.clientMessageId,
        );
      }
    },
  );

  test('terminal failure stops recovery', () async {
    await repository.sendRequest(
      _request(clientMessageId: _clientMessageId, createdAt: _historyTime(0)),
    );
    final timer = recoveryTimers.single;
    final next = repository.events.first;
    session.eventController.add(
      TravelResponseFailedEventModel.fromJson(
        _event(
          type: 'travel.response.failed',
          payload: {
            'client_message_id': _clientMessageId,
            'conversation_id': _conversationId,
            'code': 'attempts_exhausted',
          },
        ),
      ),
    );
    await next;
    expect(timer.isActive, isFalse);
    timer.fire();
    expect(session.sentRequests, hasLength(1));
    expect(await localDataSource.getPendingRequests(), isEmpty);
  });

  test(
    'disconnect stops timer and reconnect replays without a new message ID',
    () async {
      await repository.sendRequest(
        _request(clientMessageId: _clientMessageId, createdAt: _historyTime(0)),
      );
      final timer = recoveryTimers.single;
      session.isReady = false;
      session.readinessController.add(false);
      await _eventually(() => !timer.isActive);
      timer.fire();
      expect(session.sentRequests, hasLength(1));
      session.isReady = true;
      session.readinessController.add(true);
      await _eventually(
        () => session.sentRequests.length == 2 && recoveryTimers.last != timer,
      );
      expect(session.sentRequests.last.clientMessageId, _clientMessageId);
      expect(recoveryTimers.last.delay, AssistantPolicy.initialRecoveryDelay);
    },
  );

  test('explicit disconnect and dispose suppress recovery', () async {
    await repository.sendRequest(
      _request(clientMessageId: _clientMessageId, createdAt: _historyTime(0)),
    );
    final timer = recoveryTimers.single;
    await repository.disconnect();
    session.readinessController.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(timer.isActive, isFalse);
    timer.fire();
    expect(session.sentRequests, hasLength(1));
    repository.connect();
    session.readinessController.add(true);
    await _eventually(
      () => session.sentRequests.length == 2 && recoveryTimers.last != timer,
    );
    final current = recoveryTimers.last;
    await repository.dispose();
    expect(current.isActive, isFalse);
    current.fire();
    expect(session.sentRequests, hasLength(2));
  });

  test('cached completion during replay does not rearm recovery', () async {
    await repository.sendRequest(
      _request(clientMessageId: _clientMessageId, createdAt: _historyTime(0)),
    );
    final gate = Completer<void>();
    final started = Completer<void>();
    session.sendObserver = (_) async {
      started.complete();
      await gate.future;
    };
    recoveryTimers.single.fire();
    await started.future;
    final next = repository.events.first;
    session.eventController.add(
      TravelResponseCompletedEventModel.fromJson(
        _event(
          type: 'travel.response.completed',
          payload: {
            'client_message_id': _clientMessageId,
            'conversation_id': _conversationId,
            'assistant_message_id': _assistantMessageId,
            'content': 'Cached reply',
            'is_duplicate': true,
          },
        ),
      ),
    );
    await next;
    gate.complete();
    await _eventually(() => session.sentRequests.length == 2);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(recoveryTimers.where((timer) => timer.isActive), isEmpty);
    expect(await localDataSource.getPendingRequests(), isEmpty);
    expect(
      await repository
          .watchMessages(conversationLocalId: _localConversationId)
          .first,
      hasLength(2),
    );
  });

  test('deleted outbox drains recovery without recreating a request', () async {
    await repository.sendRequest(
      _request(clientMessageId: _clientMessageId, createdAt: _historyTime(0)),
    );
    final timer = recoveryTimers.single;
    await repository.deleteConversation(localId: _localConversationId);
    timer.fire();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(session.sentRequests, hasLength(1));
    expect(recoveryTimers.where((timer) => timer.isActive), isEmpty);
  });

  test('transient send failure recovers with one shared timer', () async {
    session.sendError = WebSocketFailure(kind: WebSocketFailureKind.connection);
    await repository.sendRequest(
      _request(clientMessageId: _clientMessageId, createdAt: _historyTime(0)),
    );
    await repository.sendRequest(
      _request(clientMessageId: _clientMessageId2, createdAt: _historyTime(1)),
    );
    expect(recoveryTimers.where((timer) => timer.isActive), hasLength(1));
    session.sendError = null;
    final timer = recoveryTimers.single;
    timer.fire();
    await _eventually(
      () => session.sentRequests.length == 4 && recoveryTimers.last != timer,
    );
    expect(session.sentRequests.map((request) => request.clientMessageId), [
      _clientMessageId,
      _clientMessageId2,
      _clientMessageId,
      _clientMessageId2,
    ]);
    expect(recoveryTimers.where((timer) => timer.isActive), hasLength(1));
  });

  test('queues offline without invoking transport', () async {
    session.isReady = false;
    final request = _request(
      clientMessageId: _clientMessageId2,
      createdAt: _historyTime(1),
    );
    await repository.sendRequest(request);
    expect(session.sentRequests, isEmpty);
    expect(
      await localDataSource.getPendingRequest(
        clientMessageId: request.clientMessageId,
      ),
      isNotNull,
    );
  });

  test(
    'retains transient failures for replay without failing submission',
    () async {
      session.sendError = WebSocketFailure(
        kind: WebSocketFailureKind.connection,
      );
      final request = _request(
        clientMessageId: _clientMessageId2,
        createdAt: _historyTime(1),
      );
      await repository.sendRequest(request);
      expect(
        await localDataSource.getPendingRequest(
          clientMessageId: request.clientMessageId,
        ),
        isNotNull,
      );
      expect(
        (await localDataSource.getUserMessageByClientMessageId(
          clientMessageId: request.clientMessageId,
        ))!.deliveryState,
        AssistantMessageDeliveryState.pending,
      );
    },
  );

  test('oversized request fails locally and cannot replay', () async {
    final failure = WebSocketFailure(
      kind: WebSocketFailureKind.messageTooLarge,
    );
    session.sendError = failure;
    final request = _request(
      clientMessageId: _clientMessageId2,
      createdAt: _historyTime(1),
    );
    await expectLater(repository.sendRequest(request), throwsA(same(failure)));
    expect(
      await localDataSource.getPendingRequest(
        clientMessageId: request.clientMessageId,
      ),
      isNull,
    );
    expect(
      (await localDataSource.getUserMessageByClientMessageId(
        clientMessageId: request.clientMessageId,
      ))!.deliveryState,
      AssistantMessageDeliveryState.failed,
    );
  });

  test(
    'authentication failure surfaces without deleting queued request',
    () async {
      final failure = WebSocketFailure(kind: WebSocketFailureKind.unauthorized);
      session.sendError = failure;
      final request = _request(
        clientMessageId: _clientMessageId2,
        createdAt: _historyTime(1),
      );
      await expectLater(
        repository.sendRequest(request),
        throwsA(same(failure)),
      );
      expect(
        await localDataSource.getPendingRequest(
          clientMessageId: request.clientMessageId,
        ),
        isNotNull,
      );
    },
  );

  test('ready notification during replay triggers another pass', () async {
    final snapshotRead = Completer<void>();
    countingLocalDataSource.pendingRequestsReadObserver = () {
      countingLocalDataSource.pendingRequestsReadObserver = null;
      session.readinessController.add(true);
      snapshotRead.complete();
    };
    session.readinessController.add(true);
    await snapshotRead.future;
    // The second ready notification arrives while the first pass is active.
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (countingLocalDataSource.pendingRequestsReadCount < 2) {
      if (DateTime.now().isAfter(deadline)) fail('Replay wake-up was lost');
      await Future<void>.delayed(Duration.zero);
    }
    expect(countingLocalDataSource.pendingRequestsReadCount, 2);
  });

  test('terminal failure rolls back if outbox deletion fails', () async {
    session.isReady = false;
    final request = _request(
      clientMessageId: _clientMessageId2,
      createdAt: _historyTime(1),
    );
    await repository.sendRequest(request);
    await database.customStatement(
      "CREATE TRIGGER reject_outbox_delete BEFORE DELETE ON assistant_pending_requests BEGIN SELECT RAISE(ABORT, 'simulated storage failure'); END",
    );
    await expectLater(
      localDataSource.failPendingRequest(
        clientMessageId: request.clientMessageId,
      ),
      throwsA(isA<Exception>()),
    );
    expect(
      (await localDataSource.getUserMessageByClientMessageId(
        clientMessageId: request.clientMessageId,
      ))!.deliveryState,
      AssistantMessageDeliveryState.pending,
    );
    expect(
      await localDataSource.getPendingRequest(
        clientMessageId: request.clientMessageId,
      ),
      isNotNull,
    );
  });

  test('local failure preserves accepted messages and other owners', () async {
    session.isReady = false;
    final request = _request(
      clientMessageId: _clientMessageId2,
      createdAt: _historyTime(1),
    );
    await repository.sendRequest(request);
    final otherOwner = DriftAssistantLocalDataSource(
      database: database,
      ownerId: 'other-user',
    );
    await otherOwner.failPendingRequest(
      clientMessageId: request.clientMessageId,
    );
    expect(
      (await localDataSource.getUserMessageByClientMessageId(
        clientMessageId: request.clientMessageId,
      ))!.deliveryState,
      AssistantMessageDeliveryState.pending,
    );
    await localDataSource.updateMessageDeliveryState(
      messageId: request.clientMessageId,
      deliveryState: AssistantMessageDeliveryState.sent,
      updatedAt: request.createdAt,
    );
    await localDataSource.failPendingRequest(
      clientMessageId: request.clientMessageId,
    );
    expect(
      (await localDataSource.getUserMessageByClientMessageId(
        clientMessageId: request.clientMessageId,
      ))!.deliveryState,
      AssistantMessageDeliveryState.sent,
    );
    expect(
      await localDataSource.getPendingRequest(
        clientMessageId: request.clientMessageId,
      ),
      isNotNull,
    );
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
    final eventsDone = repository.events.drain<void>();

    repository.connect();
    await repository.disconnect();
    session.readinessController.add(true);

    expect(repository.isReady, isTrue);
    expect(await nextReadiness, isTrue);
    expect(session.connectCalls, 1);
    expect(session.disconnectCalls, 1);

    await repository.dispose();
    expect(session.disposeCalls, 1);
    await eventsDone;
    await repository.dispose();
    expect(session.disposeCalls, 1);
    expect(repository.connect, throwsStateError);
  });

  test('disconnect is safe after disposal has started', () async {
    final disposing = repository.dispose();

    await repository.disconnect();
    await disposing;

    expect(session.disconnectCalls, 0);
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

  test('preserves unexpected transport send failures', () async {
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

    final storedMessage = await localDataSource.getUserMessageByClientMessageId(
      clientMessageId: request.clientMessageId,
    );

    expect(storedMessage?.deliveryState, AssistantMessageDeliveryState.pending);
  });

  test('persists a pending request before invoking transport', () async {
    final request = _request(
      clientMessageId: _clientMessageId2,
      createdAt: _historyTime(1),
    );
    var observedPersistedState = false;

    session.sendObserver = (_) async {
      final conversation = await localDataSource.getConversation(
        localId: request.conversationLocalId,
      );
      final message = await localDataSource.getUserMessageByClientMessageId(
        clientMessageId: request.clientMessageId,
      );

      expect(conversation, isNotNull);
      expect(message?.content, request.message);
      expect(message?.deliveryState, AssistantMessageDeliveryState.pending);
      observedPersistedState = true;
    };

    await repository.sendRequest(request);

    expect(observedPersistedState, isTrue);
    expect(session.sentRequests, hasLength(1));
  });

  test('reuses the cached remote conversation ID', () async {
    await localDataSource.upsertConversation(_conversation());
    final request = _request(
      clientMessageId: _clientMessageId2,
      createdAt: _historyTime(1),
    );

    await repository.sendRequest(request);

    expect(session.sentRequests.single.conversationId, _conversationId);
  });

  test('suppresses a duplicate request already completed', () async {
    final request = _request(
      clientMessageId: _clientMessageId2,
      createdAt: _historyTime(1),
    );
    await localDataSource.upsertConversationWithMessages(
      conversation: _conversation(),
      messages: [
        _message(
          id: request.clientMessageId,
          clientMessageId: request.clientMessageId,
          createdAt: request.createdAt,
          deliveryState: AssistantMessageDeliveryState.completed,
        ),
      ],
    );

    await repository.sendRequest(request);

    expect(session.sentRequests, isEmpty);
  });

  test('rejects retrying a failed request with the same ID', () async {
    final request = _request(
      clientMessageId: _clientMessageId3,
      createdAt: _historyTime(2),
    );
    await localDataSource.upsertConversationWithMessages(
      conversation: _conversation(),
      messages: [
        _message(
          id: request.clientMessageId,
          clientMessageId: request.clientMessageId,
          createdAt: request.createdAt,
          deliveryState: AssistantMessageDeliveryState.failed,
        ),
      ],
    );

    await expectLater(
      repository.sendRequest(request),
      throwsA(isA<StateError>()),
    );
    expect(session.sentRequests, isEmpty);
  });

  test('rejects a client message ID reused with different content', () async {
    final request = _request(
      clientMessageId: _clientMessageId4,
      createdAt: _historyTime(3),
      message: 'Plan Islamabad',
    );
    await localDataSource.upsertConversationWithMessages(
      conversation: _conversation(),
      messages: [
        _message(
          id: request.clientMessageId,
          clientMessageId: request.clientMessageId,
          createdAt: request.createdAt,
          content: 'Plan Lahore',
        ),
      ],
    );

    await expectLater(
      repository.sendRequest(request),
      throwsA(isA<StateError>()),
    );
    expect(session.sentRequests, isEmpty);
  });

  test('rejects a conflicting remote conversation mapping', () async {
    await localDataSource.upsertConversation(_conversation());
    final request = _request(
      clientMessageId: _clientMessageId2,
      conversationId: _differentConversationId,
      createdAt: _historyTime(1),
    );

    await expectLater(
      repository.sendRequest(request),
      throwsA(isA<StateError>()),
    );
    expect(session.sentRequests, isEmpty);
  });

  test('does not invoke transport when local persistence fails', () async {
    final request = _request(
      clientMessageId: _clientMessageId2,
      createdAt: _historyTime(1),
    );
    final failure = StateError('local persistence unavailable');
    final failingRepository = DefaultAssistantRepository(
      realtimeSession: session,
      localDataSource: _FailingAssistantLocalDataSource(failure),
      remoteDataSource: remoteDataSource,
      requestExecutor: requestExecutor,
      logger: RoamlyLogger(name: 'test.assistant', sink: const NoopLogSink()),
    );
    var transportCalled = false;
    session.sendObserver = (_) async {
      transportCalled = true;
    };

    await expectLater(
      failingRepository.sendRequest(request),
      throwsA(same(failure)),
    );
    expect(transportCalled, isFalse);
    expect(session.sentRequests, isEmpty);
  });

  test('preserves errors from the realtime event stream', () async {
    final failure = StateError('stream failed');
    final nextEvent = repository.events.first;

    session.eventController.addError(failure);

    await expectLater(nextEvent, throwsA(same(failure)));
  });

  test('forwards an event and logs when cache persistence fails', () async {
    final failure = StateError('database unavailable');
    final failingSession = _FakeRealtimeSession();
    final sink = _RecordingLogSink();
    final message = _message(
      id: _clientMessageId,
      clientMessageId: _clientMessageId,
      createdAt: _historyTime(0),
    );
    final failingRepository = DefaultAssistantRepository(
      realtimeSession: failingSession,
      localDataSource: _FailingAssistantLocalDataSource(
        failure,
        conversation: _conversation(),
        message: message,
      ),
      remoteDataSource: remoteDataSource,
      requestExecutor: requestExecutor,
      logger: RoamlyLogger(name: 'test.assistant', sink: sink),
    );
    final nextEvent = failingRepository.events.first;

    failingSession.eventController.add(
      TravelRequestRejectedEventModel.fromJson(
        _event(
          type: 'travel.request.rejected',
          payload: <String, Object?>{
            'client_message_id': _clientMessageId,
            'code': 'conversation_not_found',
          },
        ),
      ),
    );

    expect(await nextEvent, isA<AssistantRequestRejected>());
    expect(sink.records, hasLength(2));
    expect(sink.records.first.fields['reason'], 'conversationNotFound');
    expect(sink.records.first.fields['clientMessageId'], _clientMessageId);
    expect(sink.records.last.fields['errorType'], 'StateError');
    for (final record in sink.records) {
      expect(record.fields, isNot(contains('message')));
      expect(record.fields, isNot(contains('content')));
    }

    await failingRepository.dispose();
    await failingSession.closeControllers();
  });

  test('persists events without an external event listener', () async {
    await _seedRequest(localDataSource, remoteConversationId: null);
    final persistedState = localDataSource
        .watchMessages(conversationLocalId: _localConversationId)
        .firstWhere(
          (messages) =>
              messages.single.deliveryState ==
              AssistantMessageDeliveryState.sent,
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

    final messages = await persistedState.timeout(const Duration(seconds: 1));
    expect(messages.single.deliveryState, AssistantMessageDeliveryState.sent);
  });

  test('persists each event once with multiple event listeners', () async {
    await _seedRequest(localDataSource, remoteConversationId: null);
    final firstListener = repository.events.first;
    final secondListener = repository.events.first;

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

    await Future.wait([firstListener, secondListener]);
    expect(countingLocalDataSource.conversationWithMessagesWrites, 1);
  });

  test(
    'retries a persisted request with microsecond timestamp precision',
    () async {
      final request = _request(
        clientMessageId: _clientMessageId2,
        createdAt: _historyTime(1).add(const Duration(microseconds: 456)),
      );
      session.sendError = StateError('temporary socket failure');

      await expectLater(repository.sendRequest(request), throwsStateError);
      session.sendError = null;
      await repository.sendRequest(request);

      expect(session.sentRequests, hasLength(2));
    },
  );

  test('rejects a persisted ID with a changed request envelope', () async {
    final request = AssistantRequest(
      conversationLocalId: _localConversationId,
      clientMessageId: _clientMessageId2,
      tripId: _tripId,
      message: 'Plan Lahore',
      locale: 'en-PK',
      createdAt: _historyTime(1),
    );
    final conflictingRequest = AssistantRequest(
      conversationLocalId: request.conversationLocalId,
      clientMessageId: request.clientMessageId,
      tripId: _differentConversationId,
      message: request.message,
      locale: 'ur-PK',
      createdAt: request.createdAt,
    );
    session.sendError = StateError('temporary socket failure');
    await expectLater(repository.sendRequest(request), throwsStateError);
    session.sendError = null;

    await expectLater(
      repository.sendRequest(conflictingRequest),
      throwsStateError,
    );

    expect(session.sentRequests, hasLength(1));
  });

  test('deduplicates concurrent sends for the same request', () async {
    final request = _request(
      clientMessageId: _clientMessageId2,
      createdAt: _historyTime(1),
    );
    final sendStarted = Completer<void>();
    final releaseSend = Completer<void>();
    var sendCalls = 0;
    session.sendObserver = (_) async {
      sendCalls++;
      if (!sendStarted.isCompleted) sendStarted.complete();
      await releaseSend.future;
    };

    final firstSend = repository.sendRequest(request);
    final secondSend = repository.sendRequest(request);
    await sendStarted.future;

    expect(identical(firstSend, secondSend), isTrue);
    expect(sendCalls, 1);

    releaseSend.complete();
    await Future.wait([firstSend, secondSend]);
    expect(session.sentRequests, hasLength(1));
  });

  test('rejects a conflicting request while its ID is in flight', () async {
    final request = _request(
      clientMessageId: _clientMessageId2,
      createdAt: _historyTime(1),
    );
    final conflictingRequest = _request(
      clientMessageId: request.clientMessageId,
      createdAt: request.createdAt,
      message: 'Plan Islamabad',
    );
    final sendStarted = Completer<void>();
    final releaseSend = Completer<void>();
    session.sendObserver = (_) async {
      if (!sendStarted.isCompleted) sendStarted.complete();
      await releaseSend.future;
    };

    final firstSend = repository.sendRequest(request);
    await sendStarted.future;

    await expectLater(
      repository.sendRequest(conflictingRequest),
      throwsStateError,
    );

    releaseSend.complete();
    await firstSend;
    expect(session.sentRequests, hasLength(1));
  });

  test('replays a durable request and retains it after acceptance', () async {
    final request = AssistantRequest(
      conversationLocalId: _localConversationId,
      clientMessageId: _clientMessageId2,
      tripId: _tripId,
      message: 'Plan Lahore',
      locale: 'en-PK',
      createdAt: _historyTime(1),
    );
    session.sendError = StateError('connection lost');
    await expectLater(repository.sendRequest(request), throwsStateError);
    expect(await localDataSource.getPendingRequests(), hasLength(1));
    await repository.dispose();

    final replaySession = _FakeRealtimeSession()..isReady = true;
    final replayed = Completer<TravelRequestEventModel>();
    replaySession.sendObserver = (model) async {
      if (!replayed.isCompleted) replayed.complete(model);
    };
    final replayRepository = DefaultAssistantRepository(
      realtimeSession: replaySession,
      localDataSource: countingLocalDataSource,
      remoteDataSource: remoteDataSource,
      requestExecutor: requestExecutor,
      logger: RoamlyLogger(
        name: 'test.assistant.replay',
        sink: const NoopLogSink(),
      ),
    );

    final replayedModel = await replayed.future.timeout(
      const Duration(seconds: 1),
    );
    expect(replayedModel.clientMessageId, request.clientMessageId);
    expect(replayedModel.tripId, request.tripId);
    expect(replayedModel.locale, request.locale);
    expect(replayedModel.message, request.message);

    final accepted = replayRepository.events.first;
    replaySession.eventController.add(
      TravelRequestAcceptedEventModel.fromJson(
        _event(
          type: 'travel.request.accepted',
          payload: <String, Object?>{
            'client_message_id': request.clientMessageId,
            'conversation_id': _conversationId,
          },
        ),
      ),
    );
    await accepted;
    expect(await localDataSource.getPendingRequests(), hasLength(1));

    await replayRepository.dispose();
    await replaySession.closeControllers();
  });

  test('replays a large outbox in bounded keyset batches', () async {
    const requestCount = AssistantPolicy.pendingReplayBatchSize + 1;
    final conversation = _conversation(remoteId: null);
    final createdAt = _historyTime(1);

    for (var index = 0; index < requestCount; index++) {
      final clientMessageId = _batchClientMessageId(index);
      final request = _request(
        clientMessageId: clientMessageId,
        createdAt: createdAt,
      );
      await localDataSource.cachePendingRequest(
        conversation: conversation,
        message: _message(
          id: clientMessageId,
          clientMessageId: clientMessageId,
          createdAt: createdAt,
        ),
        request: request,
      );
    }

    final allRequestsReplayed = Completer<void>();
    var sendCount = 0;
    session.sendObserver = (_) async {
      sendCount++;
      if (sendCount == requestCount && !allRequestsReplayed.isCompleted) {
        allRequestsReplayed.complete();
      }
    };

    session.isReady = true;
    session.readinessController.add(true);

    await allRequestsReplayed.future.timeout(const Duration(seconds: 2));
    await Future<void>.delayed(Duration.zero);

    expect(sendCount, requestCount);
    expect(countingLocalDataSource.pendingRequestsReadCount, 2);
  });

  test(
    'does not recreate a request deleted after the replay snapshot',
    () async {
      final request = _request(
        clientMessageId: _clientMessageId2,
        createdAt: _historyTime(1),
      );
      session.sendError = StateError('connection lost');

      await expectLater(repository.sendRequest(request), throwsStateError);
      expect(await localDataSource.getPendingRequests(), hasLength(1));
      expect(session.sentRequests, hasLength(1));

      final historyCleared = Completer<void>();
      countingLocalDataSource.pendingRequestsReadObserver = () {
        countingLocalDataSource.pendingRequestsReadObserver = null;
        unawaited(
          repository.clearLocalHistory().then((_) {
            historyCleared.complete();
          }),
        );
      };

      session.sendError = null;
      session.isReady = true;
      session.readinessController.add(true);

      await historyCleared.future;

      // Drain work queued after the clear, including replay preparation.
      await repository.clearLocalHistory();

      expect(session.sentRequests, hasLength(1));
      expect(await localDataSource.getPendingRequests(), isEmpty);
      expect(
        await localDataSource.getConversation(
          localId: request.conversationLocalId,
        ),
        isNull,
      );
      expect(
        await localDataSource.getUserMessageByClientMessageId(
          clientMessageId: request.clientMessageId,
        ),
        isNull,
      );
    },
  );

  test('persists an accepted request as sent and links conversation', () async {
    await repository.sendRequest(
      _request(clientMessageId: _clientMessageId, createdAt: _historyTime(0)),
    );
    final nextEvent = repository.events.first;

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
    await nextEvent;

    final message = await localDataSource.getUserMessageByClientMessageId(
      clientMessageId: _clientMessageId,
    );
    final conversation = await localDataSource.getConversation(
      localId: _localConversationId,
    );
    expect(message?.deliveryState, AssistantMessageDeliveryState.sent);
    expect(conversation?.remoteId, _conversationId);
    expect(await localDataSource.getPendingRequests(), hasLength(1));
  });

  test('persists a rejected request as failed without a remote ID', () async {
    await repository.sendRequest(
      _request(clientMessageId: _clientMessageId, createdAt: _historyTime(0)),
    );
    final nextEvent = repository.events.first;

    session.eventController.add(
      TravelRequestRejectedEventModel.fromJson(
        _event(
          type: 'travel.request.rejected',
          payload: <String, Object?>{
            'client_message_id': _clientMessageId,
            'code': 'conversation_not_found',
          },
        ),
      ),
    );
    await nextEvent;

    final message = await localDataSource.getUserMessageByClientMessageId(
      clientMessageId: _clientMessageId,
    );
    final conversation = await localDataSource.getConversation(
      localId: _localConversationId,
    );
    expect(message?.deliveryState, AssistantMessageDeliveryState.failed);
    expect(message?.failureCode, 'rejected.conversationNotFound');
    expect(conversation?.remoteId, isNull);
    expect(await localDataSource.getPendingRequests(), isEmpty);
  });

  test('persists a processing response as processing', () async {
    await repository.sendRequest(
      _request(
        clientMessageId: _clientMessageId,
        conversationId: _conversationId,
        createdAt: _historyTime(0),
      ),
    );
    final nextEvent = repository.events.first;

    session.eventController.add(
      TravelResponseProcessingEventModel.fromJson(
        _event(
          type: 'travel.response.processing',
          payload: <String, Object?>{
            'client_message_id': _clientMessageId,
            'conversation_id': _conversationId,
          },
        ),
      ),
    );
    await nextEvent;

    final message = await localDataSource.getUserMessageByClientMessageId(
      clientMessageId: _clientMessageId,
    );
    expect(message?.deliveryState, AssistantMessageDeliveryState.processing);
    expect(await localDataSource.getPendingRequests(), hasLength(1));
  });

  test('persists a failed response as failed', () async {
    await repository.sendRequest(
      _request(
        clientMessageId: _clientMessageId,
        conversationId: _conversationId,
        createdAt: _historyTime(0),
      ),
    );
    final nextEvent = repository.events.first;

    session.eventController.add(
      TravelResponseFailedEventModel.fromJson(
        _event(
          type: 'travel.response.failed',
          payload: <String, Object?>{
            'client_message_id': _clientMessageId,
            'conversation_id': _conversationId,
            'code': 'provider_error',
          },
        ),
      ),
    );
    await nextEvent;

    final message = await localDataSource.getUserMessageByClientMessageId(
      clientMessageId: _clientMessageId,
    );
    expect(message?.deliveryState, AssistantMessageDeliveryState.failed);
    expect(message?.failureCode, 'response.providerError');
    expect(await localDataSource.getPendingRequests(), isEmpty);
  });

  test('persists a completed response and its assistant message', () async {
    await repository.sendRequest(
      _request(
        clientMessageId: _clientMessageId,
        conversationId: _conversationId,
        createdAt: _historyTime(0),
      ),
    );
    final nextEvent = repository.events.first;

    session.eventController.add(
      TravelResponseCompletedEventModel.fromJson(
        _event(
          type: 'travel.response.completed',
          payload: <String, Object?>{
            'client_message_id': _clientMessageId,
            'conversation_id': _conversationId,
            'assistant_message_id': _assistantMessageId,
            'content': 'Your Lahore itinerary is ready.',
            'is_duplicate': false,
            'itinerary_id': _itineraryId,
          },
        ),
      ),
    );
    await nextEvent;

    final messages = await localDataSource
        .watchMessages(conversationLocalId: _localConversationId)
        .first;
    expect(messages, hasLength(2));
    expect(
      messages.first.deliveryState,
      AssistantMessageDeliveryState.completed,
    );
    expect(messages.last.author, AssistantMessageAuthor.assistant);
    expect(messages.last.assistantMessageId, _assistantMessageId);
    expect(messages.last.itineraryId, _itineraryId);
    expect(messages.last.content, 'Your Lahore itinerary is ready.');
    expect(await localDataSource.getPendingRequests(), isEmpty);
  });

  test('persists an input-required response as assistant history', () async {
    await repository.sendRequest(
      _request(
        clientMessageId: _clientMessageId,
        conversationId: _conversationId,
        createdAt: _historyTime(0),
      ),
    );
    final nextEvent = repository.events.first;

    session.eventController.add(
      TravelInputRequiredEventModel.fromJson(
        _event(
          type: 'travel.input.required',
          payload: <String, Object?>{
            'client_message_id': _clientMessageId,
            'conversation_id': _conversationId,
            'assistant_message_id': _assistantMessageId,
            'content': 'Select a Tokyo airport.',
            'is_duplicate': false,
            'clarification': <String, Object?>{
              'type': 'airport_selection',
              'requests': <Object?>[
                <String, Object?>{
                  'field': 'destination_airport',
                  'query': 'Tokyo',
                  'status': 'not_found',
                  'question': 'Enter a city and country.',
                  'options': <Object?>[],
                },
              ],
            },
          },
        ),
      ),
    );
    await nextEvent;

    final messages = await localDataSource
        .watchMessages(conversationLocalId: _localConversationId)
        .first;
    expect(messages, hasLength(2));
    expect(
      messages.first.deliveryState,
      AssistantMessageDeliveryState.completed,
    );
    expect(messages.last.author, AssistantMessageAuthor.assistant);
    expect(messages.last.assistantMessageId, _assistantMessageId);
    expect(messages.last.content, 'Select a Tokyo airport.');
    expect(await localDataSource.getPendingRequests(), isEmpty);
  });

  test(
    'persists responses when the client clock is ahead of the server',
    () async {
      final clientCreatedAt = _occurredAt.add(const Duration(hours: 1));
      final request = _request(
        clientMessageId: _clientMessageId2,
        createdAt: clientCreatedAt,
      );

      await repository.sendRequest(request);

      final acceptedEvent = repository.events.first;
      session.eventController.add(
        TravelRequestAcceptedEventModel.fromJson(
          _event(
            type: 'travel.request.accepted',
            payload: <String, Object?>{
              'client_message_id': request.clientMessageId,
              'conversation_id': _conversationId,
            },
          ),
        ),
      );
      await acceptedEvent;

      final acceptedMessage = await localDataSource
          .getUserMessageByClientMessageId(
            clientMessageId: request.clientMessageId,
          );

      expect(
        acceptedMessage?.deliveryState,
        AssistantMessageDeliveryState.sent,
      );
      expect(acceptedMessage?.updatedAt, clientCreatedAt);
      expect(await localDataSource.getPendingRequests(), hasLength(1));

      final completedEvent = repository.events.first;
      session.eventController.add(
        TravelResponseCompletedEventModel.fromJson(
          _event(
            type: 'travel.response.completed',
            payload: <String, Object?>{
              'client_message_id': request.clientMessageId,
              'conversation_id': _conversationId,
              'assistant_message_id': _assistantMessageId,
              'content': 'Your itinerary is ready.',
              'is_duplicate': false,
              'itinerary_id': null,
            },
          ),
        ),
      );
      await completedEvent;

      final messages = await localDataSource
          .watchMessages(conversationLocalId: request.conversationLocalId)
          .first;

      expect(messages, hasLength(2));
      expect(messages.first.author, AssistantMessageAuthor.user);
      expect(
        messages.first.deliveryState,
        AssistantMessageDeliveryState.completed,
      );
      expect(messages.last.author, AssistantMessageAuthor.assistant);
      expect(messages.last.createdAt.isAfter(messages.first.createdAt), isTrue);
      expect(await localDataSource.getPendingRequests(), isEmpty);
    },
  );

  test('does not regress a terminal message on a later event', () async {
    await _seedRequest(
      localDataSource,
      deliveryState: AssistantMessageDeliveryState.completed,
    );
    final nextEvent = repository.events.first;

    session.eventController.add(
      TravelResponseProcessingEventModel.fromJson(
        _event(
          type: 'travel.response.processing',
          payload: <String, Object?>{
            'client_message_id': _clientMessageId,
            'conversation_id': _conversationId,
          },
        ),
      ),
    );
    await nextEvent;

    final message = await localDataSource.getUserMessageByClientMessageId(
      clientMessageId: _clientMessageId,
    );
    expect(message?.deliveryState, AssistantMessageDeliveryState.completed);
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

  test('deletion removes queued messages and ignores late events', () async {
    await repository.sendRequest(
      _request(clientMessageId: _clientMessageId, createdAt: _historyTime(0)),
    );
    expect(await localDataSource.getPendingRequests(), hasLength(1));
    await repository.deleteConversation(localId: _localConversationId);
    expect(remoteDataSource.deletedConversationIds, isEmpty);
    expect(await localDataSource.getPendingRequests(), isEmpty);
    expect(
      await repository
          .watchMessages(conversationLocalId: _localConversationId)
          .first,
      isEmpty,
    );
    final next = repository.events.first;
    session.eventController.add(
      TravelRequestRejectedEventModel.fromJson(
        _event(
          type: 'travel.request.rejected',
          payload: {
            'client_message_id': _clientMessageId,
            'code': 'conversation_not_found',
          },
        ),
      ),
    );
    await next;
    expect(
      await localDataSource.getConversation(localId: _localConversationId),
      isNull,
    );
    expect(
      await repository
          .watchMessages(conversationLocalId: _localConversationId)
          .first,
      isEmpty,
    );
  });

  test('deletes a conversation and clears cached history', () async {
    final conversation = _conversation();

    await localDataSource.upsertConversation(conversation);
    await repository.deleteConversation(localId: conversation.localId);

    expect(remoteDataSource.deletedConversationIds, [_conversationId]);
    expect(
      await localDataSource.getConversation(localId: conversation.localId),
      isNull,
    );

    await localDataSource.upsertConversation(conversation);
    await repository.clearLocalHistory();

    expect(await repository.watchConversations().first, isEmpty);
  });

  test('deletes local-only conversations without a server request', () async {
    final conversation = _conversation(remoteId: null);
    await localDataSource.upsertConversation(conversation);

    await repository.deleteConversation(localId: conversation.localId);

    expect(remoteDataSource.deletedConversationIds, isEmpty);
    expect(
      await localDataSource.getConversation(localId: conversation.localId),
      isNull,
    );
  });

  test('retains local history when remote deletion fails', () async {
    final conversation = _conversation();
    final failure = StateError('remote delete failed');
    remoteDataSource.deleteError = failure;
    await localDataSource.upsertConversation(conversation);

    await expectLater(
      repository.deleteConversation(localId: conversation.localId),
      throwsA(same(failure)),
    );

    expect(
      await localDataSource.getConversation(localId: conversation.localId),
      conversation,
    );
  });

  test(
    'cleans local history when the remote conversation is already absent',
    () async {
      final conversation = _conversation();
      requestExecutor.failure = const NetworkFailure(
        code: 'resource_not_found',
        isRetryable: false,
        kind: NetworkFailureKind.notFound,
        statusCode: 404,
      );
      await localDataSource.upsertConversation(conversation);

      await repository.deleteConversation(localId: conversation.localId);

      expect(
        await localDataSource.getConversation(localId: conversation.localId),
        isNull,
      );
    },
  );
}

AssistantConversation _conversation({String? remoteId = _conversationId}) {
  return AssistantConversation(
    localId: _localConversationId,
    remoteId: remoteId,
    title: 'Repository test trip',
    createdAt: _historyTime(0),
    updatedAt: _historyTime(0),
  );
}

Future<void> _seedRequest(
  AssistantLocalDataSource localDataSource, {
  String? remoteConversationId = _conversationId,
  AssistantMessageDeliveryState deliveryState =
      AssistantMessageDeliveryState.pending,
}) {
  return localDataSource.upsertConversationWithMessages(
    conversation: _conversation(remoteId: remoteConversationId),
    messages: [
      _message(
        id: _clientMessageId,
        clientMessageId: _clientMessageId,
        createdAt: _historyTime(0),
        deliveryState: deliveryState,
      ),
    ],
  );
}

AssistantMessage _message({
  required String id,
  required String clientMessageId,
  required DateTime createdAt,
  AssistantMessageDeliveryState deliveryState =
      AssistantMessageDeliveryState.pending,
  String content = 'Plan Lahore',
}) {
  return AssistantMessage(
    id: id,
    conversationLocalId: _localConversationId,
    clientMessageId: clientMessageId,
    author: AssistantMessageAuthor.user,
    content: content,
    deliveryState: deliveryState,
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

AssistantRequest _request({
  required String clientMessageId,
  required DateTime createdAt,
  String message = 'Plan Lahore',
  String? conversationId,
}) {
  return AssistantRequest(
    conversationLocalId: _localConversationId,
    clientMessageId: clientMessageId,
    conversationId: conversationId,
    message: message,
    createdAt: createdAt,
  );
}

DateTime _historyTime(int minute) {
  return DateTime.utc(2026, 9, 18, 8, minute);
}

String _batchClientMessageId(int index) {
  final suffix = (index + 100).toString().padLeft(12, '0');
  return '60000000-0000-4000-8000-$suffix';
}
