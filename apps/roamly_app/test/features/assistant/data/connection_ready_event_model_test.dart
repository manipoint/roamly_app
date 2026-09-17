import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_ready_event_model.dart';

Map<String, Object?> _event() => {
  'version': 1,
  'type': 'connection.ready',
  'sent_at': '2026-09-16T12:00:00Z',
  'payload': <String, Object?>{
    'connection_id': 'a1b2c3d4-e5f6-47a8-90bc-d1e2f3a4b5c6',
    'heartbeat_interval_seconds': 30.0,
    'idle_timeout_seconds': 90.0,
    'max_message_bytes': 65536,
  },
};

Map<String, Object?> _payload(Map<String, Object?> event) =>
    event['payload']! as Map<String, Object?>;

void main() {
  test('parses a backend event decoded from JSON', () {
    final json = jsonDecode(jsonEncode(_event())) as Map<String, dynamic>;
    final model = ConnectionReadyEventModel.fromJson(json);

    expect(model.sentAt, DateTime.utc(2026, 9, 16, 12));
    expect(model.sentAt.isUtc, isTrue);
    expect(model.connectionId, 'a1b2c3d4-e5f6-47a8-90bc-d1e2f3a4b5c6');
    expect(model.heartbeatIntervalSeconds, 30.0);
    expect(model.idleTimeoutSeconds, 90.0);
    expect(model.maxMessageBytes, 65536);
  });

  test('accepts integer and fractional timing values', () {
    for (final heartbeat in <num>[30, 0.5, 30.25]) {
      final json = _event();
      _payload(json)['heartbeat_interval_seconds'] = heartbeat;
      _payload(json)['idle_timeout_seconds'] = 90;
      final model = ConnectionReadyEventModel.fromJson(json);
      expect(model.heartbeatIntervalSeconds, heartbeat.toDouble());
      expect(model.idleTimeoutSeconds, 90.0);
    }
  });

  test('accepts uppercase UUID hexadecimal characters', () {
    final json = _event();
    const id = 'A1B2C3D4-E5F6-47A8-90BC-D1E2F3A4B5C6';
    _payload(json)['connection_id'] = id;
    expect(ConnectionReadyEventModel.fromJson(json).connectionId, id);
  });

  test('normalizes a timezone-qualified timestamp to UTC', () {
    final json = _event()..['sent_at'] = '2026-09-16T17:00:00.123456+05:00';
    expect(
      ConnectionReadyEventModel.fromJson(json).sentAt,
      DateTime.utc(2026, 9, 16, 12, 0, 0, 123, 456),
    );
  });

  test('permits additive backend fields', () {
    final json = _event()..['future_metadata'] = true;
    _payload(json)['future_setting'] = 'unused';
    expect(ConnectionReadyEventModel.fromJson(json).maxMessageBytes, 65536);
  });

  for (final key in ['version', 'type', 'sent_at', 'payload']) {
    test('requires a non-null envelope $key', () {
      final missing = _event()..remove(key);
      final nullValue = _event()..[key] = null;
      for (final json in [missing, nullValue]) {
        expect(
          () => ConnectionReadyEventModel.fromJson(json),
          throwsFormatException,
        );
      }
    });
  }

  for (final key in [
    'connection_id',
    'heartbeat_interval_seconds',
    'idle_timeout_seconds',
    'max_message_bytes',
  ]) {
    test('requires a non-null payload $key', () {
      final missing = _event();
      _payload(missing).remove(key);
      final nullValue = _event();
      _payload(nullValue)[key] = null;
      for (final json in [missing, nullValue]) {
        expect(
          () => ConnectionReadyEventModel.fromJson(json),
          throwsFormatException,
        );
      }
    });
  }

  test('rejects unsupported or incorrectly typed protocol versions', () {
    for (final value in <Object>[0, 2, 1.0, '1', true]) {
      final json = _event()..['version'] = value;
      expect(
        () => ConnectionReadyEventModel.fromJson(json),
        throwsFormatException,
      );
    }
  });

  test('rejects a different or incorrectly typed event name', () {
    for (final value in <Object>[
      'connection.pong',
      '',
      'connection.ready ',
      1,
    ]) {
      final json = _event()..['type'] = value;
      expect(
        () => ConnectionReadyEventModel.fromJson(json),
        throwsFormatException,
      );
    }
  });

  test('rejects non-object payloads', () {
    for (final value in <Object>[
      'private-payload',
      1,
      [],
      {1: 'value'},
    ]) {
      final json = _event()..['payload'] = value;
      expect(
        () => ConnectionReadyEventModel.fromJson(json),
        throwsFormatException,
      );
    }
  });

  test('rejects invalid UUIDs without normalizing malformed input', () {
    for (final value in <Object>[
      '',
      'not-a-uuid',
      'g1b2c3d4-e5f6-47a8-90bc-d1e2f3a4b5c6',
      'a1b2c3d4_e5f6_47a8_90bc_d1e2f3a4b5c6',
      ' a1b2c3d4-e5f6-47a8-90bc-d1e2f3a4b5c6',
      123,
    ]) {
      final json = _event();
      _payload(json)['connection_id'] = value;
      expect(
        () => ConnectionReadyEventModel.fromJson(json),
        throwsFormatException,
      );
    }
  });

  for (final key in ['heartbeat_interval_seconds', 'idle_timeout_seconds']) {
    test('rejects invalid timing values in $key', () {
      for (final value in <Object>[
        0,
        -1,
        '30',
        true,
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        final json = _event();
        _payload(json)[key] = value;
        expect(
          () => ConnectionReadyEventModel.fromJson(json),
          throwsFormatException,
        );
      }
    });
  }

  test('requires heartbeat interval to be shorter than idle timeout', () {
    for (final heartbeat in [90, 91]) {
      final json = _event();
      _payload(json)['heartbeat_interval_seconds'] = heartbeat;
      expect(
        () => ConnectionReadyEventModel.fromJson(json),
        throwsFormatException,
      );
    }
  });

  test('rejects timing values above the supported socket policy', () {
    final heartbeat = _event();
    _payload(heartbeat)['heartbeat_interval_seconds'] = 300.1;
    _payload(heartbeat)['idle_timeout_seconds'] = 301;
    expect(
      () => ConnectionReadyEventModel.fromJson(heartbeat),
      throwsFormatException,
    );

    final idle = _event();
    _payload(idle)['idle_timeout_seconds'] = 600.1;
    expect(
      () => ConnectionReadyEventModel.fromJson(idle),
      throwsFormatException,
    );
  });

  test('requires a bounded positive integer message byte limit', () {
    final valid = _event();
    _payload(valid)['max_message_bytes'] = 1;
    expect(ConnectionReadyEventModel.fromJson(valid).maxMessageBytes, 1);
    _payload(valid)['max_message_bytes'] = 1024 * 1024;
    expect(
      ConnectionReadyEventModel.fromJson(valid).maxMessageBytes,
      1024 * 1024,
    );
    for (final value in <Object>[0, -1, 1024 * 1024 + 1, 1.5, '65536', true]) {
      final json = _event();
      _payload(json)['max_message_bytes'] = value;
      expect(
        () => ConnectionReadyEventModel.fromJson(json),
        throwsFormatException,
      );
    }
  });

  test('rejects invalid or timezone-free timestamps', () {
    for (final value in <Object>[
      '2026-09-16T12:00:00',
      '2026-02-30T12:00:00Z',
      'invalid',
      123,
    ]) {
      final json = _event()..['sent_at'] = value;
      expect(
        () => ConnectionReadyEventModel.fromJson(json),
        throwsFormatException,
      );
    }
  });

  test('validation errors do not expose response values or payloads', () {
    for (final key in ['type', 'sent_at', 'payload', 'connection_id']) {
      final json = _event();
      const privateValue = 'private-response-value';
      if (key == 'connection_id') {
        _payload(json)[key] = privateValue;
      } else {
        json[key] = privateValue;
      }
      expect(
        () => ConnectionReadyEventModel.fromJson(json),
        throwsA(
          isA<FormatException>()
              .having(
                (error) => error.toString(),
                'message',
                isNot(contains(privateValue)),
              )
              .having((error) => error.source, 'source', isNull),
        ),
      );
    }
  });
}
