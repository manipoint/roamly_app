import 'package:roamly_core/roamly_core.dart';

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

/// Safe transport failure with optional structured backend classification.
final class NetworkFailure extends AppFailure {
  const NetworkFailure({
    required super.code,
    required super.isRetryable,
    required this.kind,
    this.statusCode,
    this.backendCode,
  });

  final NetworkFailureKind kind;
  final int? statusCode;
  final String? backendCode;
}
