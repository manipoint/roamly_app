import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_auth/src/infrastructure/device/installation_id_generator.dart';
import 'package:roamly_auth/src/infrastructure/device/uuid_installation_id_generator.dart';

void main() {
  group('UuidInstallationIdGenerator', () {
    const uuidV4Pattern =
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';

    test('implements the installation identifier contract', () {
      const generator = UuidInstallationIdGenerator();

      expect(generator, isA<InstallationIdGenerator>());
    });

    test('generates a valid version-4 UUID', () {
      const generator = UuidInstallationIdGenerator();

      final identifier = generator.generate();

      expect(identifier, matches(RegExp(uuidV4Pattern)));
    });

    test('generates independent identifiers', () {
      const generator = UuidInstallationIdGenerator();

      final identifiers = <String>{
        for (var index = 0; index < 100; index++) generator.generate(),
      };

      expect(identifiers, hasLength(100));
      expect(identifiers, everyElement(matches(RegExp(uuidV4Pattern))));
    });
  });
}
