import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_pong_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_ready_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_accepted_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_rejected_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_response_completed_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_response_failed_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_response_processing_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/serialization/assistant_event_decoder.dart';

const _id = '00000000-0000-4000-8000-000000000001';

Map<String, Object?> _event(String type) => <String, Object?>{
  'version': 1,
  'type': type,
  'sent_at': '2026-09-17T12:00:00Z',
  'payload': <String, Object?>{
    if (type == 'connection.ready') ...{
      'connection_id': _id,
      'heartbeat_interval_seconds': 30,
      'idle_timeout_seconds': 90,
      'max_message_bytes': 65536,
    },
    if (type.startsWith('travel.')) 'client_message_id': _id,
    if (type == 'travel.request.accepted' ||
        type.startsWith('travel.response.'))
      'conversation_id': _id,
    if (type == 'travel.request.rejected') 'code': 'trip_not_found',
    if (type == 'travel.response.completed') ...{
      'assistant_message_id': _id,
      'content': 'Travel plan',
      'is_duplicate': false,
    },
    if (type == 'travel.response.failed') 'code': 'provider_error',
  },
};

void main() {
  const decoder = AssistantEventDecoder();

  final cases = <String, Type>{
    'connection.ready': ConnectionReadyEventModel,
    'connection.pong': ConnectionPongEventModel,
    'travel.request.accepted': TravelRequestAcceptedEventModel,
    'travel.request.rejected': TravelRequestRejectedEventModel,
    'travel.response.processing': TravelResponseProcessingEventModel,
    'travel.response.completed': TravelResponseCompletedEventModel,
    'travel.response.failed': TravelResponseFailedEventModel,
  };

  for (final entry in cases.entries) {
    test('decodes ${entry.key} as ${entry.value}', () {
      final event = decoder.decode(jsonEncode(_event(entry.key)));
      expect(event.runtimeType, entry.value);
      expect(event.sentAt, DateTime.utc(2026, 9, 17, 12));
    });
  }

  test('decodeJson supports an already decoded transport frame', () {
    expect(
      decoder.decodeJson(_event('connection.pong')),
      isA<ConnectionPongEventModel>(),
    );
  });

  test('rejects invalid JSON and non-object roots without leaking input', () {
    for (final text in <String>['secret', '[]', 'null', '{"secret":true}']) {
      try {
        decoder.decode(text);
        fail('Expected FormatException.');
      } on FormatException catch (error) {
        expect(error.message, isNot(contains('secret')));
      }
    }
  });

  test('rejects unknown and incorrectly typed event names', () {
    for (final type in <Object?>['future.event', '', 1, null]) {
      final json = _event('connection.pong')..['type'] = type;
      expect(() => decoder.decodeJson(json), throwsFormatException);
    }
  });

  test('delegates full envelope validation to the selected model', () {
    final json = _event('travel.response.completed')..['version'] = 2;
    expect(() => decoder.decodeJson(json), throwsFormatException);
  });
}
