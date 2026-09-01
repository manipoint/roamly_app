import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:roamly_networking/roamly_networking.dart';

import '../data/repositories/default_auth_repository.dart';
import '../data/sources/api_auth_remote_data_source.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/services/device_identity_provider.dart';
import '../infrastructure/device/default_device_identity_provider.dart';
import '../infrastructure/device/platform_device_name_provider.dart';
import '../infrastructure/device/uuid_installation_id_generator.dart';
import '../infrastructure/storage/flutter_secure_value_store.dart';
import '../infrastructure/storage/secure_auth_token_store.dart';

/// Concrete authentication depende
final class AuthDependencies {
  final AuthRepository authRepository;
  final DeviceIdentityProvider deviceIdentity;

  AuthDependencies({
    required this.authRepository,
    required this.deviceIdentity,
  });
}

/// Constructs authentication infrastructure without exposing implementation
/// details to the Flutter application.
abstract final class AuthModule {
  static AuthDependencies create({
    required ApiConfig apiConfig,
    FlutterSecureStorage? secureStorage,
    DeviceInfoPlugin? deviceInfoPlugin,
  }) {
    final secureValueStore = FlutterSecureValueStore(
      storage: secureStorage ?? const FlutterSecureStorage(),
    );
    final tokenStore = SecureAuthTokenStore(storage: secureValueStore);
    final publicDio = DioFactory.create(configuration: apiConfig);
    final authenticatedDio = DioFactory.create(configuration: apiConfig);
    authenticatedDio.interceptors.add(BearerTokenInterceptor(tokenStore));
    final remoteDataSource = ApiAuthRemoteDataSource(
      publicClient: DioApiClient(dio: publicDio),
      authenticatedClient: DioApiClient(dio: authenticatedDio),
    );
    final authRepository = DefaultAuthRepository(
      remoteDataSource: remoteDataSource,
      tokenStore: tokenStore,
      requestExecutor: const DefaultApiRequestExecutor(
        failureMapper: DefaultDioFailureMapper(),
      ),
    );
    final deviceIdentityProvider = DefaultDeviceIdentityProvider(
      secureValueStore: secureValueStore,
      installationIdGenerator: const UuidInstallationIdGenerator(),
      deviceNameProvider: PlatformDeviceNameProvider(
        deviceInfoPlugin: deviceInfoPlugin ?? DeviceInfoPlugin(),
      ),
    );

    return AuthDependencies(
      authRepository: authRepository,
      deviceIdentity: deviceIdentityProvider,
    );
  }
}
