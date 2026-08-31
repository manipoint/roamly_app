import 'dart:convert';

import '../../data/models/auth_token_pair_model.dart';
import '../../data/storage/auth_token_store.dart';
import 'secure_value_store.dart';

final class SecureAuthTokenStore implements AuthTokenStore {
  SecureAuthTokenStore({required this._storage});
  static const _tokenKey = 'roamly.auth.tokens.v1';
  final SecureValueStore _storage;
  AuthTokenPairModel? _cachedTokens;
  bool _cacheInitialized = false;
  Future<AuthTokenPairModel?>? _readInFlight;
  int _cacheGeneration = 0;
  @override
  Future<void> clearTokens() async {
    _cacheGeneration++;
    _cachedTokens = null;
    _cacheInitialized = true;

    await _storage.delete(key: _tokenKey);
  }

  @override
  Future<String?> readAccessToken() async {
    final tokens = await readTokens();
    return tokens?.accessToken;
  }

  @override
  Future<AuthTokenPairModel?> readTokens() {
    if (_cacheInitialized) {
      return Future<AuthTokenPairModel?>.value(_cachedTokens);
    }
    return _readInFlight ??= _loadTokens();
  }

  @override
  Future<void> writeTokens(AuthTokenPairModel tokens) async {
    final generation = ++_cacheGeneration;
    final encoded = jsonEncode(<String, Object?>{
      'access_token': tokens.accessToken,
      'refresh_token': tokens.refreshToken,
      'token_type': tokens.tokenType,
      'access_token_expires_at': tokens.accessTokenExpiresAt
          .toUtc()
          .toIso8601String(),
      'refresh_token_expires_at': tokens.refreshTokenExpiresAt
          .toUtc()
          .toIso8601String(),
    });
    await _storage.write(key: _tokenKey, value: encoded);
    if (generation == _cacheGeneration) {
      _cachedTokens = tokens;
      _cacheInitialized = true;
    }
  }

  Future<AuthTokenPairModel?> _loadTokens() async {
    final generation = _cacheGeneration;
    try {
      final encoded = await _storage.read(key: _tokenKey);
      if (generation != _cacheGeneration) {
        return _cachedTokens;
      }
      if (encoded == null) {
        _cachedTokens = null;
        _cacheInitialized = true;
        return null;
      }
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        throw const FormatException(
          'Stored authentication tokens must be a JSON object',
        );
      }
      final tokens = AuthTokenPairModel.fromJson(
        Map<String, Object?>.from(decoded),
      );
      if (generation != _cacheGeneration) {
        return _cachedTokens;
      }
      _cachedTokens = tokens;
      _cacheInitialized = true;
      return tokens;
    } finally {
      _readInFlight = null;
    }
  }
}
