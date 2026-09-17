import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/data/serialization/assistant_event_reader.dart';

Map<String, Object?> _event() => {
  'version': 1,
  'type': 'connection.ready',
  'sent_at': '2026-09-17T17:00:00+05:00',
  'payload': <String, Object?>{
    'connection_id': 'A1B2C3D4-E5F6-47A8-90BC-D1E2F3A4B5C6',
  },
};

AssistantEventReader _read(Map<String, Object?> json) =>
    AssistantEventReader.fromJson(json, expectedType: 'connection.ready');

void main() {
  test('reads UTC timestamp and preserves UUID casing', () {
    final event = _read(_event());
    expect(event.sentAt, DateTime.utc(2026, 9, 17, 12));
    expect(event.uuid('connection_id'), 'A1B2C3D4-E5F6-47A8-90BC-D1E2F3A4B5C6');
  });

  test('requires supported integer protocol version', () {
    for (final version in <Object?>[null, '1', 1.0, 0, 2]) {
      expect(
        () => _read(_event()..['version'] = version),
        throwsFormatException,
      );
    }
  });

  test('requires exact event type without exposing received values', () {
    expect(
      () => _read(_event()..['type'] = 'private-server-value'),
      throwsA(
        isA<FormatException>()
            .having(
              (error) => error.toString(),
              'message',
              isNot(contains('private-server-value')),
            )
            .having((error) => error.source, 'source', isNull),
      ),
    );
  });

  test('requires every envelope field', () {
    for (final field in ['version', 'type', 'sent_at', 'payload']) {
      expect(() => _read(_event()..remove(field)), throwsFormatException);
    }
  });

  test('rejects invalid timestamps and non-object payloads', () {
    expect(
      () => _read(_event()..['sent_at'] = '2026-09-17T12:00:00'),
      throwsFormatException,
    );
    for (final payload in <Object?>[
      null,
      [],
      'text',
      {1: 'value'},
    ]) {
      expect(
        () => _read(_event()..['payload'] = payload),
        throwsFormatException,
      );
    }
  });

  test('UUID reader rejects absent, wrong-type and malformed values', () {
    for (final value in <Object?>[
      null,
      123,
      '',
      'private-invalid-uuid',
      'g1b2c3d4-e5f6-47a8-90bc-d1e2f3a4b5c6',
    ]) {
      final event = _read(_event()..['payload'] = {'id': value});
      expect(() => event.uuid('id'), throwsFormatException);
    }
    expect(() => _read(_event()).uuid('absent'), throwsFormatException);
  });

  test('allows additive fields and exposes feature payload readers', () {
    final event = _read(
      _event()
        ..['new_envelope_field'] = true
        ..['payload'] = {'enabled': true},
    );
    expect(event.payload.boolean('enabled'), isTrue);
  });
}
