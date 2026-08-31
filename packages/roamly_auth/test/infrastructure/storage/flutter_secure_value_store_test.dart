import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_auth/src/infrastructure/storage/flutter_secure_value_store.dart';

void main() {
  const storage = FlutterSecureStorage();
  const store = FlutterSecureValueStore(storage: storage);

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('FlutterSecureValueStore', () {
    test('reads a value from platform-backed secure storage', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'auth.access_token': 'stored-token',
      });

      final value = await store.read(key: 'auth.access_token');

      expect(value, 'stored-token');
    });

    test('returns null when a key does not exist', () async {
      final value = await store.read(key: 'missing-key');

      expect(value, isNull);
    });

    test('writes and replaces a value for the requested key', () async {
      await store.write(key: 'auth.access_token', value: 'first-token');
      await store.write(key: 'auth.access_token', value: 'rotated-token');

      expect(await store.read(key: 'auth.access_token'), 'rotated-token');
    });

    test('deletes only the requested key', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'auth.access_token': 'stored-token',
        'auth.installation_id': 'installation-id',
      });

      await store.delete(key: 'auth.access_token');

      expect(await store.read(key: 'auth.access_token'), isNull);
      expect(await store.read(key: 'auth.installation_id'), 'installation-id');
    });
  });
}
