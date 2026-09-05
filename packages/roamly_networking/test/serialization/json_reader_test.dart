import 'package:roamly_networking/roamly_networking.dart';
import 'package:test/test.dart';

void main() {
  test('string preserves text unless trimming is requested', () {
    final reader = JsonReader({'name': ' Lahore ', 'emoji': '🌍'});
    expect(reader.string('name'), ' Lahore ');
    expect(reader.string('name', trim: true, maxLength: 6), 'Lahore');
    expect(reader.string('emoji', maxLength: 1), '🌍');
    expect(() => reader.string('name', maxLength: 2), throwsFormatException);
  });

  test('required, explicit null and optional missing are distinct', () {
    final reader = JsonReader({'value': null, 'bad': 7});
    expect(() => reader.string('missing'), throwsFormatException);
    expect(() => reader.string('value'), throwsFormatException);
    expect(reader.nullable('value', () => reader.string('value')), isNull);
    expect(
      () => reader.nullable('missing', () => 'fallback'),
      throwsFormatException,
    );
    expect(
      reader.nullable('missing', () => 'fallback', allowMissing: true),
      isNull,
    );
    expect(
      () => reader.nullable('bad', () => reader.string('bad')),
      throwsFormatException,
    );
  });

  test('numbers reject coercion, truncation and nonfinite values', () {
    final reader = JsonReader({
      'int': 31,
      'double': 31.5,
      'text': '31',
      'nan': double.nan,
      'infinity': double.infinity,
    });
    expect(reader.integer('int'), 31);
    expect(reader.number('int'), 31.0);
    expect(reader.number('double', min: -90, max: 90), 31.5);
    expect(() => reader.integer('double'), throwsFormatException);
    for (final key in ['text', 'nan', 'infinity']) {
      expect(() => reader.number(key), throwsFormatException);
    }
    expect(() => reader.number('int', max: 30), throwsFormatException);
    expect(() => reader.integer('int', min: 32), throwsFormatException);
    expect(() => reader.number('int', min: 2, max: 1), throwsArgumentError);
  });

  test('boolean rejects strings and numeric substitutes', () {
    final reader = JsonReader({
      'yes': true,
      'no': false,
      'text': 'true',
      'int': 1,
    });
    expect(reader.boolean('yes'), isTrue);
    expect(reader.boolean('no'), isFalse);
    expect(() => reader.boolean('text'), throwsFormatException);
    expect(() => reader.boolean('int'), throwsFormatException);
  });

  test('object requires string keys and returns immutable data', () {
    final reader = JsonReader({
      'object': {'name': 'Lahore'},
      'bad': {1: 'x'},
    });
    expect(reader.object('object')['name'], 'Lahore');
    expect(() => reader.object('object').clear(), throwsUnsupportedError);
    expect(() => reader.object('bad'), throwsFormatException);
  });

  test('list checks bounds before parsing and validates each item', () {
    final reader = JsonReader({
      'items': [1, 2],
      'bad': [1, '2'],
    });
    int parse(Object? value) {
      if (value is! int) throw const FormatException('Expected integer item.');
      return value;
    }

    final items = reader.list('items', parseItem: parse, maxLength: 2);
    expect(items, [1, 2]);
    expect(() => items.clear(), throwsUnsupportedError);
    expect(() => reader.list('bad', parseItem: parse), throwsFormatException);
    expect(
      () => reader.list(
        'items',
        parseItem: (_) => fail('Must not parse'),
        maxLength: 1,
      ),
      throwsFormatException,
    );
  });

  test('reader copies input fields and does not leak invalid values', () {
    final source = <String, Object?>{'secret': 'sensitive-value'};
    final reader = JsonReader(source);
    source.clear();
    expect(reader.string('secret'), 'sensitive-value');
    try {
      reader.integer('secret');
      fail('Expected parsing failure');
    } on FormatException catch (error) {
      expect(error.toString(), isNot(contains('sensitive-value')));
    }
  });
}
