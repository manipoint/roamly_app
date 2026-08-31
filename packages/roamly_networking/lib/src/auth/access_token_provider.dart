/// Supplies the current access token to authenticated network transports.
abstract interface class AccessTokenProvider {
  /// Returns the current access token, or `null` when no session exists.
  ///
  /// Implementations must not log or expose the returned token.
  Future<String?> readAccessToken();
}
