import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_logging/roamly_logging.dart';

import '../../domain/entities/auth_device.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/services/device_identity_provider.dart';
import '../storage/secure_value_store.dart';
import 'device_name_provider.dart';
import 'installation_id_generator.dart';

/// Provides a stable identity for the current Roamly installation.
///
/// The installation identifier is generated once and persisted in secure
/// storage. Device-name resolution is best-effort and must not prevent
/// authentication.
final class DefaultDeviceIdentityProvider implements DeviceIdentityProvider {
  const DefaultDeviceIdentityProvider({
    required SecureValueStore secureValueStore,
    required InstallationIdGenerator installationIdGenerator,
    required DeviceNameProvider deviceNameProvider,
    required RoamlyLogger logger,
  }) : _secureValueStore = secureValueStore,
       _installationIdGenerator = installationIdGenerator,
       _deviceNameProvider = deviceNameProvider,
       _logger = logger;

  static const String _installationIdKey = 'auth.installation_id';

  final SecureValueStore _secureValueStore;
  final InstallationIdGenerator _installationIdGenerator;
  final DeviceNameProvider _deviceNameProvider;
  final RoamlyLogger _logger;

  @override
  Future<Result<AuthDevice>> getCurrentDevice() async {
    try {
      final installationId = await _getOrCreateInstallationId();

      if (installationId == null) {
        _logger.error('Installation identifier generation returned no value');
        return const FailureResult<AuthDevice>(AuthFailure.deviceIdentity());
      }

      final deviceName = await _getOptionalDeviceName();

      return Success<AuthDevice>(
        AuthDevice(id: installationId, name: deviceName),
      );
    } on Exception catch (error, stackTrace) {
      _logger.error(
        'Failed to resolve device identity',
        fields: {'error_type': error.runtimeType.toString()},
        stackTrace: stackTrace,
      );
      return const FailureResult<AuthDevice>(AuthFailure.deviceIdentity());
    }
  }

  Future<String?> _getOrCreateInstallationId() async {
    final storedId = await _secureValueStore.read(key: _installationIdKey);

    final normalizedStoredId = _normalize(storedId);

    if (normalizedStoredId != null) {
      return normalizedStoredId;
    }

    final generatedId = _normalize(_installationIdGenerator.generate());

    if (generatedId == null) {
      return null;
    }

    await _secureValueStore.write(key: _installationIdKey, value: generatedId);

    return generatedId;
  }

  Future<String?> _getOptionalDeviceName() async {
    try {
      return _normalize(await _deviceNameProvider.getDeviceName());
    } on Exception catch (error, stackTrace) {
      _logger.debug(
        'Optional device name unavailable',
        fields: {'error_type': error.runtimeType.toString()},
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  static String? _normalize(String? value) {
    final normalizedValue = value?.trim();

    if (normalizedValue == null || normalizedValue.isEmpty) {
      return null;
    }

    return normalizedValue;
  }
}
