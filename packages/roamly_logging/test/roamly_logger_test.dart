import 'package:roamly_logging/roamly_logging.dart';
import 'package:test/test.dart';

void main() {
  group('RoamlyLogger', () {
    final timestamp = DateTime.utc(2026, 9, 4, 10, 30);

    test('writes a structured record', () {
      final sink = _RecordingLogSink();
      final logger = RoamlyLogger(
        name: 'auth',
        sink: sink,
        clock: () => timestamp,
      );

      logger.info('Sign-in started', fields: const {'attempt': 1});

      expect(sink.records, hasLength(1));
      final record = sink.records.single;
      expect(record.timestamp, timestamp);
      expect(record.level, LogLevel.info);
      expect(record.loggerName, 'auth');
      expect(record.message, 'Sign-in started');
      expect(record.fields, const {'attempt': 1});
    });

    test('filters records below the configured minimum level', () {
      final sink = _RecordingLogSink();
      final logger = RoamlyLogger(
        name: 'networking',
        sink: sink,
        minimumLevel: LogLevel.warning,
      );

      logger.debug('Debug event');
      logger.info('Info event');
      logger.warning('Warning event');

      expect(sink.records.map((record) => record.level), [LogLevel.warning]);
    });

    test('preserves a debug stack trace without requiring a raw error', () {
      final sink = _RecordingLogSink();
      final stackTrace = StackTrace.current;
      final logger = RoamlyLogger(
        name: 'device',
        sink: sink,
        minimumLevel: LogLevel.debug,
      );

      logger.debug('Optional metadata unavailable', stackTrace: stackTrace);

      expect(sink.records.single.stackTrace, same(stackTrace));
      expect(sink.records.single.error, isNull);
    });

    test('maps convenience methods to their expected severity', () {
      final sink = _RecordingLogSink();
      final logger = RoamlyLogger(
        name: 'app',
        sink: sink,
        minimumLevel: LogLevel.trace,
      );

      logger.trace('trace');
      logger.debug('debug');
      logger.info('info');
      logger.warning('warning');
      logger.error('error');
      logger.fatal('fatal');

      expect(sink.records.map((record) => record.level), LogLevel.values);
    });

    test('redacts nested credentials without hiding token metrics', () {
      final sink = _RecordingLogSink();
      final logger = RoamlyLogger(name: 'api', sink: sink);

      logger.info(
        'Request completed',
        fields: const {
          'access_token': 'access-secret',
          'token_count': 120,
          'headers': {
            'Authorization': 'Bearer secret',
            'content-type': 'application/json',
          },
        },
      );

      final fields = sink.records.single.fields;
      expect(fields['access_token'], LogSanitizer.redactedValue);
      expect(fields['token_count'], 120);
      expect(fields['headers'], {
        'Authorization': LogSanitizer.redactedValue,
        'content-type': 'application/json',
      });
    });

    test('normalizes values that structured sinks can serialize', () {
      final sink = _RecordingLogSink();
      final logger = RoamlyLogger(name: 'travel', sink: sink);
      final date = DateTime.parse('2026-09-04T15:30:00+05:00');

      logger.info(
        'Trip loaded',
        fields: {
          'date': date,
          'level': LogLevel.info,
          'ids': const {1, 2},
          'uri': Uri.parse('https://example.com/trips?access_token=secret'),
        },
      );

      expect(sink.records.single.fields, {
        'date': '2026-09-04T10:30:00.000Z',
        'level': 'info',
        'ids': [1, 2],
        'uri': 'https://example.com/trips',
      });
    });

    test('creates a child logger with a hierarchical name', () {
      final sink = _RecordingLogSink();
      final logger = RoamlyLogger(name: 'roamly', sink: sink);

      logger.child('auth').info('Session restored');

      expect(sink.records.single.loggerName, 'roamly.auth');
    });

    test('does not allow a failing sink to break application code', () {
      final logger = RoamlyLogger(name: 'app', sink: const _ThrowingLogSink());

      expect(() => logger.info('Still safe'), returnsNormally);
    });

    test('stores immutable structured fields', () {
      final sink = _RecordingLogSink();
      final logger = RoamlyLogger(name: 'app', sink: sink);

      logger.info('Immutable');

      expect(
        () => sink.records.single.fields['new'] = 'value',
        throwsUnsupportedError,
      );
    });
  });
}

final class _RecordingLogSink implements LogSink {
  final List<LogRecord> records = [];

  @override
  void write(LogRecord record) {
    records.add(record);
  }
}

final class _ThrowingLogSink implements LogSink {
  const _ThrowingLogSink();

  @override
  void write(LogRecord record) {
    throw StateError('sink failed');
  }
}
