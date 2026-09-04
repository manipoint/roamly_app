import 'log_level.dart';
import 'log_record.dart';
import 'log_sanitizer.dart';
import 'log_sink.dart';

typedef LogClock = DateTime Function();

/// Structured logger used by Roamly application and infrastructure code.
final class RoamlyLogger {
  RoamlyLogger({
    required String name,
    required this.sink,
    this.minimumLevel = LogLevel.info,
    LogClock? clock,
    this.sanitizer = const LogSanitizer(),
  }) : assert(name.trim().isNotEmpty, 'name must not be empty'),
       name = name.trim(),
       _clock = clock ?? DateTime.now;

  final String name;
  final LogSink sink;
  final LogLevel minimumLevel;
  final LogSanitizer sanitizer;
  final LogClock _clock;

  /// Creates a namespaced logger that shares this logger's configuration.
  RoamlyLogger child(String childName) {
    assert(childName.trim().isNotEmpty, 'childName must not be empty');

    return RoamlyLogger(
      name: '$name.${childName.trim()}',
      sink: sink,
      minimumLevel: minimumLevel,
      clock: _clock,
      sanitizer: sanitizer,
    );
  }

  void trace(String message, {Map<String, Object?> fields = const {}}) {
    log(LogLevel.trace, message, fields: fields);
  }

  void debug(
    String message, {
    Map<String, Object?> fields = const {},
    StackTrace? stackTrace,
  }) {
    log(LogLevel.debug, message, fields: fields, stackTrace: stackTrace);
  }

  void info(String message, {Map<String, Object?> fields = const {}}) {
    log(LogLevel.info, message, fields: fields);
  }

  void warning(
    String message, {
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      LogLevel.warning,
      message,
      fields: fields,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void error(
    String message, {
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      LogLevel.error,
      message,
      fields: fields,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void fatal(
    String message, {
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      LogLevel.fatal,
      message,
      fields: fields,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void log(
    LogLevel level,
    String message, {
    Map<String, Object?> fields = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.value < minimumLevel.value) {
      return;
    }

    final record = LogRecord(
      timestamp: _clock().toUtc(),
      level: level,
      loggerName: name,
      message: message,
      fields: sanitizer.sanitize(fields),
      error: error,
      stackTrace: stackTrace,
    );

    try {
      sink.write(record);
    } on Object {
      // Observability must never terminate an application workflow.
    }
  }
}
