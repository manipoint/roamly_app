import 'package:roamly_core/roamly_core.dart';
import 'package:test/test.dart';

void main() {
  test('normalizes required and optional trimmed text', () {
    expect(RoamlyValueNormalizers.trimmed('  Lahore  '), 'Lahore');
    expect(RoamlyValueNormalizers.optionalTrimmed(null), isNull);
    expect(RoamlyValueNormalizers.optionalTrimmed('   '), isNull);
    expect(RoamlyValueNormalizers.optionalTrimmed('  Trip  '), 'Trip');
  });

  test('normalizes timestamps to UTC', () {
    final local = DateTime.parse('2026-09-18T13:00:00+05:00');
    expect(
      RoamlyValueNormalizers.utc(local),
      DateTime.parse('2026-09-18T08:00:00Z'),
    );
  });
}
