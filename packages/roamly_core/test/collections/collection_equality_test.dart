import 'package:roamly_core/roamly_core.dart';
import 'package:test/test.dart';

void main() {
  group('CollectionEquality.ordered', () {
    test('accepts identical and value-equal lists', () {
      final values = <int>[1, 2];

      expect(CollectionEquality.ordered(values, values), isTrue);
      expect(CollectionEquality.ordered(values, <int>[1, 2]), isTrue);
    });

    test('rejects different lengths, values, and ordering', () {
      expect(CollectionEquality.ordered(<int>[1], <int>[1, 2]), isFalse);
      expect(CollectionEquality.ordered(<int>[1, 2], <int>[1, 3]), isFalse);
      expect(CollectionEquality.ordered(<int>[1, 2], <int>[2, 1]), isFalse);
    });
  });

  group('CollectionEquality.unordered', () {
    test('accepts identical sets regardless of insertion order', () {
      final values = <int>{1, 2};

      expect(CollectionEquality.unordered(values, values), isTrue);
      expect(CollectionEquality.unordered(values, <int>{2, 1}), isTrue);
    });

    test('rejects different lengths and values', () {
      expect(CollectionEquality.unordered(<int>{1}, <int>{1, 2}), isFalse);
      expect(CollectionEquality.unordered(<int>{1, 2}, <int>{1, 3}), isFalse);
    });
  });
}
