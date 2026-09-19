import 'package:roamly_core/roamly_core.dart';
import 'package:test/test.dart';

void main() {
  const uuid = '00000000-0000-4000-8000-000000000001';

  test('UUID guards return valid values and support null optionals', () {
    expect(RoamlyValueGuards.requireUuid(uuid, field: 'id'), uuid);
    expect(RoamlyValueGuards.requireOptionalUuid(null, field: 'id'), isNull);
  });

  test('UUID guard errors do not expose rejected values', () {
    const rejected = 'private-invalid-value';

    expect(
      () => RoamlyValueGuards.requireUuid(rejected, field: 'id'),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.toString(),
          'message',
          isNot(contains(rejected)),
        ),
      ),
    );
  });

  test('non-blank guard preserves original formatting', () {
    const formatted = '  formatted response\n';
    expect(
      RoamlyValueGuards.requireNonBlank(formatted, field: 'content'),
      formatted,
    );
    expect(
      () => RoamlyValueGuards.requireNonBlank('  ', field: 'content'),
      throwsArgumentError,
    );
  });

  test('rune-length guard applies supplied bounds', () {
    expect(
      RoamlyValueGuards.requireRuneLength(
        'Lahore',
        field: 'message',
        minimum: 1,
        maximum: 20,
      ),
      'Lahore',
    );
    expect(
      () => RoamlyValueGuards.requireRuneLength(
        'too long',
        field: 'message',
        minimum: 1,
        maximum: 3,
      ),
      throwsArgumentError,
    );
  });

  test('chronology guard preserves valid values and rejects earlier ones', () {
    final minimum = DateTime.parse('2026-09-18T10:00:00Z');
    final value = minimum.add(const Duration(minutes: 1));

    expect(
      RoamlyValueGuards.requireNotBefore(
        value: value,
        minimum: minimum,
        field: 'updatedAt',
      ),
      value,
    );
    expect(
      () => RoamlyValueGuards.requireNotBefore(
        value: minimum.subtract(const Duration(microseconds: 1)),
        minimum: minimum,
        field: 'updatedAt',
      ),
      throwsArgumentError,
    );
  });
}
