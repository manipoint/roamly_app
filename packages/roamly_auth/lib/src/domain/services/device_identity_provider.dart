import '../entities/auth_device.dart';

/// Provides the stable identity of the current Roamly installation.
abstract interface class DeviceIdentityProvider {
  Future<AuthDevice> getCurrentDevice();
}
