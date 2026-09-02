import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  group('RoamlyRadii', () {
    test('defines the approved corner-radius scale', () {
      expect(RoamlyRadii.smallValue, 8);
      expect(RoamlyRadii.mediumValue, 12);
      expect(RoamlyRadii.largeValue, 16);
      expect(RoamlyRadii.extraLargeValue, 24);
    });

    test('applies each radius value uniformly to every corner', () {
      const radii = <(BorderRadius, double)>[
        (RoamlyRadii.small, RoamlyRadii.smallValue),
        (RoamlyRadii.medium, RoamlyRadii.mediumValue),
        (RoamlyRadii.large, RoamlyRadii.largeValue),
        (RoamlyRadii.extraLarge, RoamlyRadii.extraLargeValue),
        (RoamlyRadii.pill, 999),
      ];

      for (final (borderRadius, expectedValue) in radii) {
        expect(borderRadius.topLeft.x, expectedValue);
        expect(borderRadius.topRight.x, expectedValue);
        expect(borderRadius.bottomLeft.x, expectedValue);
        expect(borderRadius.bottomRight.x, expectedValue);
      }
    });
  });
}
