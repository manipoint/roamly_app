import 'log_level.dart';

/// Immutable structured event passed from a logger to a [LogSink].
final class LogRecord {
  LogRecord({
    required this.timestamp,
    required this.level,
    required this.loggerName,
    required this.message,
    Map<String, Object?> fields = const {},
    this.error,
    this.stackTrace,
  }) : fields = Map.unmodifiable(fields);

  final DateTime timestamp;
  final LogLevel level;
  final String loggerName;
  final String message;
  final Map<String, Object?> fields;
  final Object? error;
  final StackTrace? stackTrace;
}
