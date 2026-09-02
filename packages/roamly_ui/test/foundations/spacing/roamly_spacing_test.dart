import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  group('RoamlySpacing', () {
    test('defines the approved spacing scale', () {
      expect(
        const [
          RoamlySpacing.none,
          RoamlySpacing.space4,
          RoamlySpacing.space8,
          RoamlySpacing.space12,
          RoamlySpacing.space16,
          RoamlySpacing.space20,
          RoamlySpacing.space24,
          RoamlySpacing.space32,
          RoamlySpacing.space40,
          RoamlySpacing.space48,
          RoamlySpacing.space64,
        ],
        const [0, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64],
      );
    });

    test('keeps non-zero spacing values on the four-point grid', () {
      const values = [
        RoamlySpacing.space4,
        RoamlySpacing.space8,
        RoamlySpacing.space12,
        RoamlySpacing.space16,
        RoamlySpacing.space20,
        RoamlySpacing.space24,
        RoamlySpacing.space32,
        RoamlySpacing.space40,
        RoamlySpacing.space48,
        RoamlySpacing.space64,
      ];

      expect(values.every((value) => value % 4 == 0), isTrue);
    });
  });
}
