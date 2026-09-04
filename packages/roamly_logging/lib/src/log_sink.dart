import 'log_record.dart';

/// Destination for structured log records.
abstract interface class LogSink {
  void write(LogRecord record);
}

/// Explicitly discards logs, useful when a feature should remain silent.
final class NoopLogSink implements LogSink {
  const NoopLogSink();

  @override
  void write(LogRecord record) {}
}
