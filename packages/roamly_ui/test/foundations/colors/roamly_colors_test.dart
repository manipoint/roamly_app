import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  group('RoamlyColors', () {
    test('matches the approved brand palette', () {
      expect(RoamlyColors.deepInk.toARGB32(), 0xFF0B1220);
      expect(RoamlyColors.indigo.toARGB32(), 0xFF5B5CF6);
      expect(RoamlyColors.blue.toARGB32(), 0xFF2563EB);
      expect(RoamlyColors.cyan.toARGB32(), 0xFF22C3EE);
      expect(RoamlyColors.teal.toARGB32(), 0xFF2DD4BF);
      expect(RoamlyColors.background.toARGB32(), 0xFFF6F7FB);
      expect(RoamlyColors.white.toARGB32(), 0xFFFFFFFF);
    });

    test('defines opaque colors', () {
      const colors = [
        RoamlyColors.deepInk,
        RoamlyColors.indigo,
        RoamlyColors.blue,
        RoamlyColors.cyan,
        RoamlyColors.teal,
        RoamlyColors.background,
        RoamlyColors.white,
      ];

      expect(colors.every((color) => color.a == 1), isTrue);
    });
  });
}
