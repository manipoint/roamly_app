/// Provides a best-effort human-readable name for the current device.
abstract interface class DeviceNameProvider {
  Future<String?> getDeviceName();
}
