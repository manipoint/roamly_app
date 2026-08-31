import 'package:roamly_core/roamly_core.dart';

import '../entities/auth_device.dart';

/// Provides the stable identity of the current Roamly installation.
abstract interface class DeviceIdentityProvider {
  Future<Result<AuthDevice>> getCurrentDevice();
}
