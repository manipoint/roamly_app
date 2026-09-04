/// Severity assigned to a Roamly log record.
enum LogLevel {
  trace(500),
  debug(700),
  info(800),
  warning(900),
  error(1000),
  fatal(1200);

  const LogLevel(this.value);

  /// Numeric value understood by `dart:developer` and observability systems.
  final int value;
}
