import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_auth/src/data/models/auth_token_pair_model.dart';
import 'package:roamly_auth/src/infrastructure/storage/secure_auth_token_store.dart';
import 'package:roamly_auth/src/infrastructure/storage/secure_value_store.dart';

final class FakeSecureValueStore implements SecureValueStore {
  final Map<String, String> values = <String, String>{};

  int readCalls = 0;
  int writeCalls = 0;
  int deleteCalls = 0;
  Object? readError;
  Object? writeError;
  Object? deleteError;
  Completer<String?>? pendingRead;
  String? lastWriteKey;
  String? lastWriteValue;

  @override
  Future<String?> read({required String key}) async {
    readCalls++;
    if (readError case final error?) {
      throw error;
    }
    if (pendingRead case final pending?) {
      return pending.future;
    }
    return values[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    writeCalls++;
    if (writeError case final error?) {
      throw error;
    }
    lastWriteKey = key;
    lastWriteValue = value;
    values[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    deleteCalls++;
    if (deleteError case final error?) {
      throw error;
    }
    values.remove(key);
  }
}

void main() {
  const tokenStorageKey = 'roamly.auth.tokens.v1';

  AuthTokenPairModel tokens({
    String accessToken = 'access-token',
    String refreshToken = 'refresh-token',
  }) {
    return AuthTokenPairModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: 'bearer',
      accessTokenExpiresAt: DateTime.utc(2026, 8, 31, 10, 45),
      refreshTokenExpiresAt: DateTime.utc(2026, 9, 30, 10, 30),
    );
  }

  String encodeTokens(AuthTokenPairModel value) {
    return jsonEncode(<String, Object?>{
      'access_token': value.accessToken,
      'refresh_token': value.refreshToken,
      'token_type': value.tokenType,
      'access_token_expires_at': value.accessTokenExpiresAt.toIso8601String(),
      'refresh_token_expires_at': value.refreshTokenExpiresAt.toIso8601String(),
    });
  }

  void expectTokens(AuthTokenPairModel? actual, AuthTokenPairModel expected) {
    expect(actual, isNotNull);
    expect(actual?.accessToken, expected.accessToken);
    expect(actual?.refreshToken, expected.refreshToken);
    expect(actual?.tokenType, expected.tokenType);
    expect(actual?.accessTokenExpiresAt, expected.accessTokenExpiresAt);
    expect(actual?.refreshTokenExpiresAt, expected.refreshTokenExpiresAt);
  }

  group('SecureAuthTokenStore', () {
    test('loads and caches a persisted token pair', () async {
      final storage = FakeSecureValueStore();
      final expected = tokens();
      storage.values[tokenStorageKey] = encodeTokens(expected);
      final store = SecureAuthTokenStore(storage: storage);

      expectTokens(await store.readTokens(), expected);
      expectTokens(await store.readTokens(), expected);
      expect(storage.readCalls, 1);
    });

    test('caches an absent persisted session', () async {
      final storage = FakeSecureValueStore();
      final store = SecureAuthTokenStore(storage: storage);

      expect(await store.readTokens(), isNull);
      expect(await store.readTokens(), isNull);
      expect(storage.readCalls, 1);
    });

    test('shares one secure read between concurrent callers', () async {
      final storage = FakeSecureValueStore();
      final pendingRead = Completer<String?>();
      storage.pendingRead = pendingRead;
      final expected = tokens();
      final store = SecureAuthTokenStore(storage: storage);

      final first = store.readTokens();
      final second = store.readTokens();
      await Future<void>.delayed(Duration.zero);
      expect(storage.readCalls, 1);

      pendingRead.complete(encodeTokens(expected));
      expectTokens(await first, expected);
      expectTokens(await second, expected);
    });

    test('writes the complete pair and serves it from memory', () async {
      final storage = FakeSecureValueStore();
      final store = SecureAuthTokenStore(storage: storage);
      final expected = tokens();

      await store.writeTokens(expected);

      expect(storage.writeCalls, 1);
      expect(storage.lastWriteKey, tokenStorageKey);
      expect(storage.lastWriteValue, isNotNull);
      expect(storage.lastWriteValue, isNot(contains('AuthTokenPairModel')));
      expectTokens(await store.readTokens(), expected);
      expect(storage.readCalls, 0);
    });

    test('provides only the cached access token to networking', () async {
      final storage = FakeSecureValueStore();
      final store = SecureAuthTokenStore(storage: storage);
      await store.writeTokens(tokens());

      expect(await store.readAccessToken(), 'access-token');
      expect(storage.readCalls, 0);
    });

    test('clears persistent and in-memory credentials', () async {
      final storage = FakeSecureValueStore();
      final store = SecureAuthTokenStore(storage: storage);
      await store.writeTokens(tokens());

      await store.clearTokens();

      expect(storage.deleteCalls, 1);
      expect(storage.values[tokenStorageKey], isNull);
      expect(await store.readTokens(), isNull);
      expect(await store.readAccessToken(), isNull);
    });

    test('clears the memory cache even when deletion fails', () async {
      final storage = FakeSecureValueStore();
      final store = SecureAuthTokenStore(storage: storage);
      await store.writeTokens(tokens());
      final deleteError = StateError('secure deletion failed');
      storage.deleteError = deleteError;

      await expectLater(store.clearTokens(), throwsA(same(deleteError)));

      expect(await store.readAccessToken(), isNull);
    });

    test('does not cache corrupted persisted credentials', () async {
      final storage = FakeSecureValueStore();
      storage.values[tokenStorageKey] = 'not-json';
      final store = SecureAuthTokenStore(storage: storage);

      await expectLater(store.readTokens(), throwsFormatException);
      await expectLater(store.readTokens(), throwsFormatException);

      expect(storage.readCalls, 2);
    });

    test('does not cache tokens when persistence fails', () async {
      final storage = FakeSecureValueStore();
      final writeError = StateError('secure write failed');
      storage.writeError = writeError;
      final store = SecureAuthTokenStore(storage: storage);

      await expectLater(store.writeTokens(tokens()), throwsA(same(writeError)));
      storage.writeError = null;

      expect(await store.readTokens(), isNull);
      expect(storage.readCalls, 1);
    });

    test('a pending read cannot restore tokens after logout', () async {
      final storage = FakeSecureValueStore();
      final pendingRead = Completer<String?>();
      storage.pendingRead = pendingRead;
      final store = SecureAuthTokenStore(storage: storage);

      final pendingTokens = store.readTokens();
      await Future<void>.delayed(Duration.zero);
      await store.clearTokens();

      pendingRead.complete(encodeTokens(tokens()));

      expect(await pendingTokens, isNull);
      expect(await store.readAccessToken(), isNull);
    });
  });
}
