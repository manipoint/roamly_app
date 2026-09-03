import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  group('RoamlyBreakpoints', () {
    test('classifies widths below 600 as compact', () {
      expect(RoamlyBreakpoints.classify(0), RoamlyWindowClass.compact);
      expect(RoamlyBreakpoints.classify(599.9), RoamlyWindowClass.compact);
    });

    test('classifies widths from 600 to below 840 as medium', () {
      expect(RoamlyBreakpoints.classify(600), RoamlyWindowClass.medium);
      expect(RoamlyBreakpoints.classify(839.9), RoamlyWindowClass.medium);
    });

    test('classifies widths from 840 upwards as expanded', () {
      expect(RoamlyBreakpoints.classify(840), RoamlyWindowClass.expanded);
      expect(
        RoamlyBreakpoints.classify(double.infinity),
        RoamlyWindowClass.expanded,
      );
    });

    test('rejects invalid widths', () {
      expect(() => RoamlyBreakpoints.classify(-0.1), throwsArgumentError);
      expect(() => RoamlyBreakpoints.classify(double.nan), throwsArgumentError);
    });
  });
}
