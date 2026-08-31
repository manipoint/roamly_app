import 'package:roamly_networking/roamly_networking.dart';

import '../models/auth_token_pair_model.dart';

/// Persists and provides authentication credentials.
///
/// This is an internal data-layer port and must not be exposed to UI code.
abstract interface class AuthTokenStore implements AccessTokenProvider {
  /// Returns the persisted token pair, or null when no session exists.
  Future<AuthTokenPairModel?> readTokens();

  /// Replaces the complete persisted token pair.
  Future<void> writeTokens(AuthTokenPairModel tokens);

  /// Removes credentials for the current session.
  Future<void> clearTokens();
}
