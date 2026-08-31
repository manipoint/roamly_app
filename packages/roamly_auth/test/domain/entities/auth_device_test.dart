import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_auth/roamly_auth.dart';

void main() {
  group('AuthDevice', () {
    test('preserves its installation identifier and optional name', () {
      final device = AuthDevice(
        id: 'a752dd69-d35d-4144-95ec-911fdc7ac725',
        name: 'Apple iPhone',
      );

      expect(device.id, 'a752dd69-d35d-4144-95ec-911fdc7ac725');
      expect(device.name, 'Apple iPhone');
    });

    test('allows a missing best-effort device name', () {
      final device = AuthDevice(id: 'a752dd69-d35d-4144-95ec-911fdc7ac725');

      expect(device.name, isNull);
    });

    test('uses value equality for identical properties', () {
      final first = AuthDevice(
        id: 'a752dd69-d35d-4144-95ec-911fdc7ac725',
        name: 'Apple iPhone',
      );
      final second = AuthDevice(
        id: 'a752dd69-d35d-4144-95ec-911fdc7ac725',
        name: 'Apple iPhone',
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('distinguishes devices with different properties', () {
      final device = AuthDevice(
        id: 'a752dd69-d35d-4144-95ec-911fdc7ac725',
        name: 'Apple iPhone',
      );

      expect(
        device,
        isNot(
          AuthDevice(
            id: '6c154d10-5cf4-4487-a1e2-08c8a818cb95',
            name: 'Apple iPhone',
          ),
        ),
      );
      expect(
        device,
        isNot(
          AuthDevice(
            id: 'a752dd69-d35d-4144-95ec-911fdc7ac725',
            name: 'Android Phone',
          ),
        ),
      );
    });
  });
}
