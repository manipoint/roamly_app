import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_pong_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_accepted_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_input_required_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_response_completed_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_response_failed_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_response_processing_event_model.dart';

const _clientId = '00000000-0000-4000-8000-000000000001';
const _conversationId = '00000000-0000-4000-8000-000000000002';
const _assistantId = '00000000-0000-4000-8000-000000000003';
const _itineraryId = '00000000-0000-4000-8000-000000000004';

Map<String, Object?> _event(String type) => {
  'version': 1,
  'type': type,
  'sent_at': '2026-09-17T12:00:00Z',
  'payload': <String, Object?>{
    if (type != 'connection.pong') ...{
      'client_message_id': _clientId,
      'conversation_id': _conversationId,
    },
    if (type == 'travel.response.completed') ...{
      'assistant_message_id': _assistantId,
      'content': '  Your plan\nDay one  ',
      'is_duplicate': true,
      'itinerary_id': _itineraryId,
    },
    if (type == 'travel.input.required') ...{
      'assistant_message_id': _assistantId,
      'content': 'Select a London airport.',
      'is_duplicate': false,
      'clarification': <String, Object?>{
        'type': 'airport_selection',
        'requests': <Object?>[
          <String, Object?>{
            'field': 'origin_airport',
            'query': 'London',
            'status': 'selection_required',
            'question': 'Select an airport.',
            'options': <Object?>[
              <String, Object?>{
                'provider_location_id': 'london-city',
                'iata_code': 'LON',
                'location_type': 'city',
                'name': 'London',
                'city_name': 'London',
                'country_name': 'United Kingdom',
                'country_code': 'GB',
              },
              <String, Object?>{
                'provider_location_id': 'heathrow',
                'iata_code': 'LHR',
                'location_type': 'airport',
                'name': 'London Heathrow Airport',
                'city_name': 'London',
                'country_name': 'United Kingdom',
                'country_code': 'GB',
              },
            ],
          },
        ],
      },
    },
    if (type == 'travel.response.failed') 'code': 'provider_error',
  },
};

Map<String, Object?> _payload(Map<String, Object?> event) =>
    event['payload']! as Map<String, Object?>;

void main() {
  final parsers = <String, Object Function(Map<String, Object?>)>{
    'connection.pong': ConnectionPongEventModel.fromJson,
    'travel.request.accepted': TravelRequestAcceptedEventModel.fromJson,
    'travel.input.required': TravelInputRequiredEventModel.fromJson,
    'travel.response.processing': TravelResponseProcessingEventModel.fromJson,
    'travel.response.completed': TravelResponseCompletedEventModel.fromJson,
    'travel.response.failed': TravelResponseFailedEventModel.fromJson,
  };

  for (final entry in parsers.entries) {
    final type = entry.key;
    final parse = entry.value;
    test('$type preserves payload and timestamp', () {
      final model = parse(_event(type));
      final (sentAt, clientId, conversationId) = switch (model) {
        ConnectionPongEventModel() => (model.sentAt, null, null),
        TravelRequestAcceptedEventModel() => (
          model.sentAt,
          model.clientMessageId,
          model.conversationId,
        ),
        TravelInputRequiredEventModel() => (
          model.sentAt,
          model.clientMessageId,
          model.conversationId,
        ),
        TravelResponseProcessingEventModel() => (
          model.sentAt,
          model.clientMessageId,
          model.conversationId,
        ),
        TravelResponseCompletedEventModel() => (
          model.sentAt,
          model.clientMessageId,
          model.conversationId,
        ),
        TravelResponseFailedEventModel() => (
          model.sentAt,
          model.clientMessageId,
          model.conversationId,
        ),
        _ => throw StateError('Unexpected model'),
      };
      expect(sentAt, DateTime.utc(2026, 9, 17, 12));
      if (type != 'connection.pong') {
        expect(clientId, _clientId);
        expect(conversationId, _conversationId);
      }
    });

    test('$type rejects incorrect envelopes', () {
      for (final change in <String, Object?>{
        'version': 2,
        'type': 'wrong.event',
        'sent_at': 'invalid',
        'payload': [],
      }.entries) {
        expect(
          () => parse(_event(type)..[change.key] = change.value),
          throwsFormatException,
        );
      }
    });

    if (type != 'connection.pong') {
      test('$type validates every required correlation ID', () {
        for (final field in [
          'client_message_id',
          'conversation_id',
          if (type == 'travel.response.completed' ||
              type == 'travel.input.required')
            'assistant_message_id',
        ]) {
          final json = _event(type);
          _payload(json)[field] = 'invalid';
          expect(() => parse(json), throwsFormatException);
          _payload(json).remove(field);
          expect(() => parse(json), throwsFormatException);
        }
      });
    }
  }

  test('completed preserves text, duplicate flag and assistant identity', () {
    final model = TravelResponseCompletedEventModel.fromJson(
      _event('travel.response.completed'),
    );
    expect(model.content, '  Your plan\nDay one  ');
    expect(model.isDuplicate, isTrue);
    expect(model.assistantMessageId, _assistantId);
    expect(model.itineraryId, _itineraryId);
  });

  test('input-required preserves text and typed airport choices', () {
    final model = TravelInputRequiredEventModel.fromJson(
      _event('travel.input.required'),
    );

    expect(model.content, 'Select a London airport.');
    expect(model.isDuplicate, isFalse);
    expect(model.assistantMessageId, _assistantId);
    expect(model.clarification.requests.single.options.first.iataCode, 'LON');
  });

  test(
    'completed accepts absent or null itinerary and rejects invalid UUID',
    () {
      final json = _event('travel.response.completed');
      _payload(json).remove('itinerary_id');
      expect(
        TravelResponseCompletedEventModel.fromJson(json).itineraryId,
        isNull,
      );
      _payload(json)['itinerary_id'] = null;
      expect(
        TravelResponseCompletedEventModel.fromJson(json).itineraryId,
        isNull,
      );
      _payload(json)['itinerary_id'] = 'invalid';
      expect(
        () => TravelResponseCompletedEventModel.fromJson(json),
        throwsFormatException,
      );
    },
  );

  test('completed rejects empty content and non-boolean duplicate flag', () {
    for (final content in <Object?>[null, '', ' \n ', 42]) {
      final json = _event('travel.response.completed');
      _payload(json)['content'] = content;
      expect(
        () => TravelResponseCompletedEventModel.fromJson(json),
        throwsFormatException,
      );
    }
    final json = _event('travel.response.completed');
    _payload(json)['is_duplicate'] = 'true';
    expect(
      () => TravelResponseCompletedEventModel.fromJson(json),
      throwsFormatException,
    );
  });

  test('failed maps known codes and preserves safe unknown fallback', () {
    for (final entry in {
      'provider_error': TravelResponseFailureCode.providerError,
      'generation_failed': TravelResponseFailureCode.generationFailed,
      'attempts_exhausted': TravelResponseFailureCode.attemptsExhausted,
      'future_code': TravelResponseFailureCode.unknown,
    }.entries) {
      final json = _event('travel.response.failed');
      _payload(json)['code'] = ' ${entry.key} ';
      expect(TravelResponseFailedEventModel.fromJson(json).code, entry.value);
    }
    for (final code in <Object?>[null, '', ' ', 123]) {
      final json = _event('travel.response.failed');
      _payload(json)['code'] = code;
      expect(
        () => TravelResponseFailedEventModel.fromJson(json),
        throwsFormatException,
      );
    }
  });
}
