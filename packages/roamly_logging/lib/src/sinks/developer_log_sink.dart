import 'dart:convert';
import 'dart:developer' as developer;

import '../log_record.dart';
import '../log_sink.dart';

/// Writes structured records to the Dart developer timeline and console.
final class DeveloperLogSink implements LogSink {
  const DeveloperLogSink();

  @override
  void write(LogRecord record) {
    final message = record.fields.isEmpty
        ? record.message
        : '${record.message} ${jsonEncode(record.fields)}';

    developer.log(
      message,
      time: record.timestamp,
      level: record.level.value,
      name: record.loggerName,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  }
}
