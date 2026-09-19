import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/data/mappers/assistant_event_model_mapper.dart';
import 'package:roamly_app/src/features/assistant/data/models/assistant_incoming_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_pong_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_ready_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_accepted_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_rejected_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_response_completed_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_response_failed_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_response_processing_event_model.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_event.dart';

const _clientMessageId = '00000000-0000-4000-8000-000000000001';
const _conversationId = '00000000-0000-4000-8000-000000000002';
const _assistantMessageId = '00000000-0000-4000-8000-000000000003';
const _itineraryId = '00000000-0000-4000-8000-000000000004';
const _connectionId = '00000000-0000-4000-8000-000000000005';
const _sentAtText = '2026-09-18T08:30:00+05:00';
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

final class _UnsupportedEventModel implements AssistantIncomingEventModel {
  @override
  DateTime get sentAt => _occurredAt;
}

void main() {
  const mapper = AssistantEventModelMapper();

  group('connection events', () {
    test('filters connection.ready', () {
      final model = ConnectionReadyEventModel.fromJson(
        _event(
          type: 'connection.ready',
          payload: <String, Object?>{
            'connection_id': _connectionId,
            'heartbeat_interval_seconds': 20,
            'idle_timeout_seconds': 60,
            'max_message_bytes': 4096,
          },
        ),
      );

      expect(mapper.mapOrNull(model), isNull);
    });

    test('filters connection.pong', () {
      final model = ConnectionPongEventModel.fromJson(
        _event(type: 'connection.pong', payload: <String, Object?>{}),
      );

      expect(mapper.mapOrNull(model), isNull);
    });
  });

  test('maps an accepted request', () {
    final model = TravelRequestAcceptedEventModel.fromJson(
      _event(
        type: 'travel.request.accepted',
        payload: <String, Object?>{
          'client_message_id': _clientMessageId,
          'conversation_id': _conversationId,
        },
      ),
    );

    expect(
      mapper.mapOrNull(model),
      AssistantRequestAccepted(
        occurredAt: _occurredAt,
        clientMessageId: _clientMessageId,
        conversationId: _conversationId,
      ),
    );
  });

  group('rejection reason mapping', () {
    const cases = <String, AssistantRequestRejectionReason>{
      'conversation_not_found':
          AssistantRequestRejectionReason.conversationNotFound,
      'client_message_conflict':
          AssistantRequestRejectionReason.clientMessageConflict,
      'trip_not_found': AssistantRequestRejectionReason.tripNotFound,
      'future_rejection_code': AssistantRequestRejectionReason.unknown,
    };

    for (final entry in cases.entries) {
      test('maps ${entry.key}', () {
        final model = TravelRequestRejectedEventModel.fromJson(
          _event(
            type: 'travel.request.rejected',
            payload: <String, Object?>{
              'client_message_id': _clientMessageId,
              'code': entry.key,
            },
          ),
        );

        expect(
          mapper.mapOrNull(model),
          AssistantRequestRejected(
            occurredAt: _occurredAt,
            clientMessageId: _clientMessageId,
            reason: entry.value,
          ),
        );
      });
    }
  });

  test('maps a processing response', () {
    final model = TravelResponseProcessingEventModel.fromJson(
      _event(
        type: 'travel.response.processing',
        payload: <String, Object?>{
          'client_message_id': _clientMessageId,
          'conversation_id': _conversationId,
        },
      ),
    );

    expect(
      mapper.mapOrNull(model),
      AssistantResponseProcessing(
        occurredAt: _occurredAt,
        clientMessageId: _clientMessageId,
        conversationId: _conversationId,
      ),
    );
  });

  test('maps a completed response and preserves its itinerary', () {
    final model = TravelResponseCompletedEventModel.fromJson(
      _event(
        type: 'travel.response.completed',
        payload: <String, Object?>{
          'client_message_id': _clientMessageId,
          'conversation_id': _conversationId,
          'assistant_message_id': _assistantMessageId,
          'content': 'Your Lahore itinerary is ready.',
          'is_duplicate': true,
          'itinerary_id': _itineraryId,
        },
      ),
    );

    expect(
      mapper.mapOrNull(model),
      AssistantResponseCompleted(
        occurredAt: _occurredAt,
        clientMessageId: _clientMessageId,
        conversationId: _conversationId,
        assistantMessageId: _assistantMessageId,
        content: 'Your Lahore itinerary is ready.',
        isDuplicate: true,
        itineraryId: _itineraryId,
      ),
    );
  });

  group('failure reason mapping', () {
    const cases = <String, AssistantResponseFailureReason>{
      'provider_error': AssistantResponseFailureReason.providerError,
      'generation_failed': AssistantResponseFailureReason.generationFailed,
      'attempts_exhausted': AssistantResponseFailureReason.attemptsExhausted,
      'future_failure_code': AssistantResponseFailureReason.unknown,
    };

    for (final entry in cases.entries) {
      test('maps ${entry.key}', () {
        final model = TravelResponseFailedEventModel.fromJson(
          _event(
            type: 'travel.response.failed',
            payload: <String, Object?>{
              'client_message_id': _clientMessageId,
              'conversation_id': _conversationId,
              'code': entry.key,
            },
          ),
        );

        expect(
          mapper.mapOrNull(model),
          AssistantResponseFailed(
            occurredAt: _occurredAt,
            clientMessageId: _clientMessageId,
            conversationId: _conversationId,
            reason: entry.value,
          ),
        );
      });
    }
  });

  test('rejects an unsupported incoming model', () {
    expect(() => mapper.mapOrNull(_UnsupportedEventModel()), throwsStateError);
  });
}
