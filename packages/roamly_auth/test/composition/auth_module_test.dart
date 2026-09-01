import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_auth/roamly_auth.dart';
import 'package:roamly_auth/src/data/repositories/default_auth_repository.dart';
import 'package:roamly_auth/src/infrastructure/device/default_device_identity_provider.dart';
import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_networking/roamly_networking.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final apiConfig = ApiConfig(
    baseUri: Uri.parse('https://api.roamly.test/'),
    connectTimeout: const Duration(seconds: 5),
    sendTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 10),
  );

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  group('AuthModule', () {
    test('constructs dependencies behind their domain contracts', () {
      final dependencies = AuthModule.create(
        apiConfig: apiConfig,
        secureStorage: const FlutterSecureStorage(),
        deviceInfoPlugin: DeviceInfoPlugin.setMockInitialValues(),
      );

      expect(dependencies.authRepository, isA<AuthRepository>());
      expect(dependencies.authRepository, isA<DefaultAuthRepository>());
      expect(dependencies.deviceIdentity, isA<DeviceIdentityProvider>());
      expect(dependencies.deviceIdentity, isA<DefaultDeviceIdentityProvider>());
    });

    test('creates independent dependency graphs', () {
      final first = AuthModule.create(
        apiConfig: apiConfig,
        secureStorage: const FlutterSecureStorage(),
        deviceInfoPlugin: DeviceInfoPlugin.setMockInitialValues(),
      );
      final second = AuthModule.create(
        apiConfig: apiConfig,
        secureStorage: const FlutterSecureStorage(),
        deviceInfoPlugin: DeviceInfoPlugin.setMockInitialValues(),
      );

      expect(first.authRepository, isNot(same(second.authRepository)));
      expect(first.deviceIdentity, isNot(same(second.deviceIdentity)));
    });

    test('provides a stable persisted installation identity', () async {
      final dependencies = AuthModule.create(
        apiConfig: apiConfig,
        secureStorage: const FlutterSecureStorage(),
        deviceInfoPlugin: DeviceInfoPlugin.setMockInitialValues(),
      );

      final firstResult = await dependencies.deviceIdentity.getCurrentDevice();
      final secondResult = await dependencies.deviceIdentity.getCurrentDevice();

      expect(firstResult, isA<Success<AuthDevice>>());
      expect(secondResult, isA<Success<AuthDevice>>());
      final firstDevice = (firstResult as Success<AuthDevice>).value;
      final secondDevice = (secondResult as Success<AuthDevice>).value;
      expect(firstDevice.id, isNotEmpty);
      expect(secondDevice.id, firstDevice.id);
    });
  });
}
