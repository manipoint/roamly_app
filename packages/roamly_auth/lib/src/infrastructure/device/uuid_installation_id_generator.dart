import 'package:uuid/uuid.dart';

import 'installation_id_generator.dart';

/// Generates random version-4 identifiers for app installations.
final class UuidInstallationIdGenerator implements InstallationIdGenerator {
  static const Uuid _uuid = Uuid();

  const UuidInstallationIdGenerator();
  @override
  String generate() {
    return _uuid.v4();
  }
}
