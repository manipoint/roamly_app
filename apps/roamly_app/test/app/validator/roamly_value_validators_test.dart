import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/app/validator/roamly_value_validators.dart';

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

  test('accepts only uppercase ISO-shaped country codes', () {
    expect(RoamlyValueValidators.isValidCountryCode('ID'), isTrue);
    expect(RoamlyValueValidators.isValidCountryCode('id'), isFalse);
    expect(RoamlyValueValidators.isValidCountryCode('123'), isFalse);
  });
}
