# Roamly Logging

Framework-independent structured logging for Roamly applications and packages.

The package provides severity filtering, hierarchical logger names, injectable
sinks, serializable structured fields, and defensive redaction of credential
metadata. Logging failures never interrupt an application workflow.

```dart
final logger = RoamlyLogger(
  name: 'roamly.auth',
  sink: const DeveloperLogSink(),
  minimumLevel: LogLevel.info,
);

logger.info('Session restored', fields: {'user_id': userId});
```

Never place credentials or personal data in a log message. Known sensitive
field names are redacted, but messages are intentionally treated as opaque
developer-authored text.
