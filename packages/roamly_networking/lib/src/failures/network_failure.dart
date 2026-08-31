import 'package:roamly_core/roamly_core.dart';

/// Describes the transport-level category of a network failure.
enum NetworkFailureKind {
  connection,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  rateLimited,
  server,
  cancelled,
  unknown,
}

/// A safe transport failure produced from an HTTP or WebSocket operation.
final class NetworkFailure extends AppFailure {
  const NetworkFailure({
    required super.code,
    required super.isRetryable,
    required this.kind,
    this.statusCode,
  });

  /// Machine-readable category used by application logic.
  final NetworkFailureKind kind;

  /// HTTP response status when one was received.
  final int? statusCode;
}
