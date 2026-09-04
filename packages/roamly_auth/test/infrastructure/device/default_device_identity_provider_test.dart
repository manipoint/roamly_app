import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_auth/roamly_auth.dart';
import 'package:roamly_auth/src/infrastructure/device/default_device_identity_provider.dart';
import 'package:roamly_auth/src/infrastructure/device/device_name_provider.dart';
import 'package:roamly_auth/src/infrastructure/device/installation_id_generator.dart';
import 'package:roamly_auth/src/infrastructure/storage/secure_value_store.dart';
import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_logging/roamly_logging.dart';

void main() {
  const installationIdKey = 'auth.installation_id';

  group('DefaultDeviceIdentityProvider', () {
    test('implements the device identity provider contract', () {
      final provider = _buildProvider();

      expect(provider, isA<DeviceIdentityProvider>());
    });

    test('returns the normalized stored installation identifier', () async {
      final storage = _FakeSecureValueStore(value: ' installation-1 ');
      final generator = _FakeInstallationIdGenerator('generated-id');
      final deviceNameProvider = _FakeDeviceNameProvider(' iPhone 16 Pro ');
      final provider = _buildProvider(
        storage: storage,
        generator: generator,
        deviceNameProvider: deviceNameProvider,
      );

      final device = _expectSuccess(await provider.getCurrentDevice());

      expect(
        device,
        const AuthDevice(id: 'installation-1', name: 'iPhone 16 Pro'),
      );
      expect(storage.readKeys, <String>[installationIdKey]);
      expect(storage.writeCalls, 0);
      expect(generator.calls, 0);
      expect(deviceNameProvider.calls, 1);
    });

    test('generates and persists an identifier when none is stored', () async {
      final storage = _FakeSecureValueStore();
      final generator = _FakeInstallationIdGenerator(' generated-id ');
      final provider = _buildProvider(storage: storage, generator: generator);

      final device = _expectSuccess(await provider.getCurrentDevice());

      expect(device.id, 'generated-id');
      expect(storage.lastWriteKey, installationIdKey);
      expect(storage.lastWriteValue, 'generated-id');
      expect(generator.calls, 1);
    });

    test('treats a blank stored identifier as missing', () async {
      final storage = _FakeSecureValueStore(value: '   ');
      final generator = _FakeInstallationIdGenerator('generated-id');
      final provider = _buildProvider(storage: storage, generator: generator);

      final device = _expectSuccess(await provider.getCurrentDevice());

      expect(device.id, 'generated-id');
      expect(storage.lastWriteValue, 'generated-id');
      expect(generator.calls, 1);
    });

    test('reuses a newly persisted identifier on later calls', () async {
      final storage = _FakeSecureValueStore();
      final generator = _FakeInstallationIdGenerator('generated-id');
      final provider = _buildProvider(storage: storage, generator: generator);

      final first = _expectSuccess(await provider.getCurrentDevice());
      final second = _expectSuccess(await provider.getCurrentDevice());

      expect(first.id, 'generated-id');
      expect(second.id, first.id);
      expect(generator.calls, 1);
      expect(storage.writeCalls, 1);
    });

    test(
      'returns device identity failure when generated id is blank',
      () async {
        final storage = _FakeSecureValueStore();
        final generator = _FakeInstallationIdGenerator('   ');
        final deviceNameProvider = _FakeDeviceNameProvider('iPhone');
        final provider = _buildProvider(
          storage: storage,
          generator: generator,
          deviceNameProvider: deviceNameProvider,
        );

        _expectDeviceIdentityFailure(await provider.getCurrentDevice());

        expect(storage.writeCalls, 0);
        expect(deviceNameProvider.calls, 0);
      },
    );

    test('returns device identity failure when secure read fails', () async {
      final storage = _FakeSecureValueStore(
        readError: Exception('secure read failed'),
      );
      final provider = _buildProvider(storage: storage);

      _expectDeviceIdentityFailure(await provider.getCurrentDevice());

      expect(storage.writeCalls, 0);
    });

    test('returns device identity failure when secure write fails', () async {
      final storage = _FakeSecureValueStore(
        writeError: Exception('secure write failed'),
      );
      final provider = _buildProvider(storage: storage);

      _expectDeviceIdentityFailure(await provider.getCurrentDevice());

      expect(storage.writeCalls, 1);
    });

    test('keeps authentication usable when device name lookup fails', () async {
      final deviceNameProvider = _FakeDeviceNameProvider(
        null,
        error: Exception('device plugin failed'),
      );
      final provider = _buildProvider(
        storage: _FakeSecureValueStore(value: 'installation-1'),
        deviceNameProvider: deviceNameProvider,
      );

      final device = _expectSuccess(await provider.getCurrentDevice());

      expect(device, const AuthDevice(id: 'installation-1'));
      expect(deviceNameProvider.calls, 1);
    });

    test('converts a blank device name to null', () async {
      final provider = _buildProvider(
        storage: _FakeSecureValueStore(value: 'installation-1'),
        deviceNameProvider: _FakeDeviceNameProvider('   '),
      );

      final device = _expectSuccess(await provider.getCurrentDevice());

      expect(device.name, isNull);
    });

    test('logs secure storage failures without exception details', () async {
      final sink = _RecordingLogSink();
      final provider = _buildProvider(
        storage: _FakeSecureValueStore(
          readError: Exception('private storage details'),
        ),
        logger: RoamlyLogger(name: 'test.device', sink: sink),
      );

      _expectDeviceIdentityFailure(await provider.getCurrentDevice());

      final record = sink.records.single;
      expect(record.level, LogLevel.error);
      expect(record.fields['error_type'], contains('Exception'));
      expect(record.error, isNull);
      expect(
        '${record.message} ${record.fields}',
        isNot(contains('private storage details')),
      );
    });
  });
}

DefaultDeviceIdentityProvider _buildProvider({
  _FakeSecureValueStore? storage,
  _FakeInstallationIdGenerator? generator,
  _FakeDeviceNameProvider? deviceNameProvider,
  RoamlyLogger? logger,
}) {
  return DefaultDeviceIdentityProvider(
    secureValueStore: storage ?? _FakeSecureValueStore(),
    installationIdGenerator:
        generator ?? _FakeInstallationIdGenerator('generated-id'),
    deviceNameProvider: deviceNameProvider ?? _FakeDeviceNameProvider(null),
    logger:
        logger ?? RoamlyLogger(name: 'test.device', sink: const NoopLogSink()),
  );
}

AuthDevice _expectSuccess(Result<AuthDevice> result) {
  expect(result, isA<Success<AuthDevice>>());
  return (result as Success<AuthDevice>).value;
}

void _expectDeviceIdentityFailure(Result<AuthDevice> result) {
  expect(result, isA<FailureResult<AuthDevice>>());
  final failure = (result as FailureResult<AuthDevice>).failure;
  expect(failure, isA<AuthFailure>());
  expect((failure as AuthFailure).kind, AuthFailureKind.deviceIdentity);
}

final class _FakeSecureValueStore implements SecureValueStore {
  _FakeSecureValueStore({this.value, this.readError, this.writeError});

  String? value;
  final Exception? readError;
  final Exception? writeError;
  final List<String> readKeys = <String>[];
  int writeCalls = 0;
  String? lastWriteKey;
  String? lastWriteValue;

  @override
  Future<String?> read({required String key}) async {
    readKeys.add(key);
    if (readError case final error?) {
      throw error;
    }
    return value;
  }

  @override
  Future<void> write({required String key, required String value}) async {
    writeCalls++;
    if (writeError case final error?) {
      throw error;
    }
    lastWriteKey = key;
    lastWriteValue = value;
    this.value = value;
  }

  @override
  Future<void> delete({required String key}) async {
    value = null;
  }
}

final class _FakeInstallationIdGenerator implements InstallationIdGenerator {
  _FakeInstallationIdGenerator(this.value);

  final String value;
  int calls = 0;

  @override
  String generate() {
    calls++;
    return value;
  }
}

final class _FakeDeviceNameProvider implements DeviceNameProvider {
  _FakeDeviceNameProvider(this.value, {this.error});

  final String? value;
  final Exception? error;
  int calls = 0;

  @override
  Future<String?> getDeviceName() async {
    calls++;
    if (error case final exception?) {
      throw exception;
    }
    return value;
  }
}

final class _RecordingLogSink implements LogSink {
  final List<LogRecord> records = [];

  @override
  void write(LogRecord record) {
    records.add(record);
  }
}
