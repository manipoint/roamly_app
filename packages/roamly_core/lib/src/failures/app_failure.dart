/// Base type for safe, expected application failures.
///
/// Failures contain machine-readable information only and must not expose raw
/// exceptions, response bodies, credentials, or user-facing localized text.
abstract base class AppFailure {
  const AppFailure({required this.code, required this.isRetryable});

  /// Stable machine-readable failure identifier.
  ///
  /// Codes use `snake_case` and should remain backward compatible.
  final String code;

  /// Whether the failed operation may be safely attempted again.
  ///
  /// This is a policy hint and does not automatically trigger a retry.
  final bool isRetryable;
}
