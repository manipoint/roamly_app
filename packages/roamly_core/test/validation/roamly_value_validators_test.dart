import 'package:roamly_core/roamly_core.dart';
import 'package:test/test.dart';

void main() {
  test('validates UUIDs without normalizing malformed input', () {
    expect(
      RoamlyValueValidators.isValidUuid('A1B2C3D4-E5F6-47A8-90BC-D1E2F3A4B5C6'),
      isTrue,
    );
    expect(RoamlyValueValidators.isValidUuid('not-a-uuid'), isFalse);
  });

  test('validates bounded lowercase slugs', () {
    expect(RoamlyValueValidators.isValidSlug('bali-indonesia'), isTrue);
    expect(RoamlyValueValidators.isValidSlug('Bali Indonesia'), isFalse);
    expect(RoamlyValueValidators.isValidSlug('a'), isFalse);
  });

  test('validates uppercase country and IATA codes', () {
    expect(RoamlyValueValidators.isValidCountryCode('ID'), isTrue);
    expect(RoamlyValueValidators.isValidCountryCode('id'), isFalse);
    expect(RoamlyValueValidators.isValidIataCode('LHE'), isTrue);
    expect(RoamlyValueValidators.isValidIataCode('lhe'), isFalse);
  });

  test('validates non-blank text and Unicode rune length', () {
    expect(RoamlyValueValidators.isNonBlank('  Lahore  '), isTrue);
    expect(RoamlyValueValidators.isNonBlank('  '), isFalse);
    expect(
      RoamlyValueValidators.hasRuneLength('🇵🇰', minimum: 2, maximum: 2),
      isTrue,
    );
    expect(
      RoamlyValueValidators.hasRuneLength('abc', minimum: 4, maximum: 2),
      isFalse,
    );
  });

  test('validates chronological ordering by instant', () {
    final minimum = DateTime.parse('2026-09-18T10:00:00Z');
    expect(RoamlyValueValidators.isNotBefore(minimum, minimum), isTrue);
    expect(
      RoamlyValueValidators.isNotBefore(
        minimum.subtract(const Duration(microseconds: 1)),
        minimum,
      ),
      isFalse,
    );
  });
}
