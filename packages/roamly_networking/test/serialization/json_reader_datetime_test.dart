import 'package:roamly_networking/roamly_networking.dart';
import 'package:test/test.dart';

void main() {
  test('timestamps normalize offsets to UTC and preserve microseconds', () {
    final reader = JsonReader({'at': '2026-09-05T12:30:00.123456+05:00'});
    expect(reader.dateTime('at'), DateTime.utc(2026, 9, 5, 7, 30, 0, 123, 456));
    expect(reader.dateTime('at').isUtc, isTrue);
  });

  test('timestamps reject missing timezone and invalid types', () {
    for (final value in <Object?>[
      null,
      123,
      'bad',
      '2026-09-05',
      '2026-09-05T12:30:00',
    ]) {
      expect(
        () => JsonReader({'at': value}).dateTime('at'),
        throwsFormatException,
      );
    }
    expect(() => JsonReader({}).dateTime('at'), throwsFormatException);
  });

  test('timestamps reject overflowing calendar and clock components', () {
    for (final value in [
      '2026-02-30T12:00:00Z',
      '2026-13-01T12:00:00Z',
      '2026-09-05T25:00:00Z',
      '2026-09-05T12:60:00Z',
      '2026-09-05T12:00:00+25:00',
    ]) {
      expect(
        () => JsonReader({'at': value}).dateTime('at'),
        throwsFormatException,
        reason: value,
      );
    }
  });
}
