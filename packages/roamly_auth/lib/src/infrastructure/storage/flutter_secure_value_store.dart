import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_value_store.dart';

final class FlutterSecureValueStore implements SecureValueStore {
  const FlutterSecureValueStore({required FlutterSecureStorage storage})
    : _storage = storage;

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete({required String key}) {
    return _storage.delete(key: key);
  }

  @override
  Future<String?> read({required String key}) {
    return _storage.read(key: key);
  }

  @override
  Future<void> write({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }
}
