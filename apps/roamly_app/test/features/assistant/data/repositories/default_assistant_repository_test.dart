import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/data/models/assistant_incoming_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_pong_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_accepted_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/repositories/default_assistant_repository.dart';
import 'package:roamly_app/src/features/assistant/data/services/assistant_realtime_session.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_event.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_request.dart';

const _clientMessageId = '00000000-0000-4000-8000-000000000001';
const _conversationId = '00000000-0000-4000-8000-000000000002';
const _tripId = '00000000-0000-4000-8000-000000000003';
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
  late _FakeRealtimeSession session;
  late DefaultAssistantRepository repository;

  setUp(() {
    session = _FakeRealtimeSession();
    repository = DefaultAssistantRepository(realtimeSession: session);
  });

  tearDown(() async {
    await session.closeControllers();
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
}
