/// Minimal secure key-value storage required by authentication infrastructure.
abstract interface class SecureValueStore {
  Future<String?> read({required String key});

  Future<void> write({required String key, required String value});

  Future<void> delete({required String key});
}
