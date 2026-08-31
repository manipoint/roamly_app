import 'device_name_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Resolves a best-effort human-readable name for the current device.
///
/// Device name resolution must never block authentication. If the platform
/// does not provide a usable name, or the plugin fails, `null` is returned.
final class PlatformDeviceNameProvider implements DeviceNameProvider {
  const PlatformDeviceNameProvider({required DeviceInfoPlugin deviceInfoPlugin})
    : _deviceInfoPlugin = deviceInfoPlugin;

  final DeviceInfoPlugin _deviceInfoPlugin;
  @override
  Future<String?> getDeviceName() async {
    try {
      final deviceInfo = await _deviceInfoPlugin.deviceInfo;
      return switch (deviceInfo) {
        AndroidDeviceInfo androidInfo => _androidDeviceName(androidInfo),
        IosDeviceInfo iosDeviceInfo => _firstNonBlank([
          iosDeviceInfo.name,
          iosDeviceInfo.modelName,
          iosDeviceInfo.model,
        ]),
        _ => null,
      };
    } on Exception {
      return null;
    }
  }

  static String? _androidDeviceName(AndroidDeviceInfo androidInfo) {
    final configuredName = androidInfo.name.trim();
    if (configuredName.isNotEmpty) {
      return configuredName;
    }
    final manufacturer = androidInfo.manufacturer.trim();
    final model = androidInfo.model.trim();

    if (model.isEmpty) {
      return manufacturer.isEmpty ? null : manufacturer;
    }
    if (manufacturer.isEmpty ||
        model.toLowerCase().startsWith(manufacturer.toLowerCase())) {
      return model;
    }
    return '$manufacturer $model';
  }

  static String? _firstNonBlank(Iterable<String?> values) {
    for (final value in values) {
      final normalizedValue = value?.trim();
      if (normalizedValue != null && normalizedValue.isNotEmpty) {
        return normalizedValue;
      }
    }
    return null;
  }
}
