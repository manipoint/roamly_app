import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  group('RoamlyColorSchemes', () {
    test('light scheme maps the brand palette to semantic roles', () {
      final scheme = RoamlyColorSchemes.light;

      expect(scheme.brightness, Brightness.light);
      expect(scheme.primary, RoamlyColors.blue);
      expect(scheme.onPrimary, RoamlyColors.white);
      expect(scheme.secondary, RoamlyColors.indigo);
      expect(scheme.onSecondary, RoamlyColors.white);
      expect(scheme.tertiary, RoamlyColors.teal);
      expect(scheme.onTertiary, RoamlyColors.deepInk);
      expect(scheme.surface, RoamlyColors.background);
      expect(scheme.onSurface, RoamlyColors.deepInk);
    });

    test('dark scheme maps the brand palette to semantic roles', () {
      final scheme = RoamlyColorSchemes.dark;

      expect(scheme.brightness, Brightness.dark);
      expect(scheme.primary, RoamlyColors.indigo);
      expect(scheme.onPrimary, RoamlyColors.white);
      expect(scheme.secondary, RoamlyColors.cyan);
      expect(scheme.onSecondary, RoamlyColors.deepInk);
      expect(scheme.tertiary, RoamlyColors.teal);
      expect(scheme.onTertiary, RoamlyColors.deepInk);
      expect(scheme.surface, RoamlyColors.deepInk);
      expect(scheme.onSurface, RoamlyColors.white);
    });

    for (final entry in <String, ColorScheme>{
      'light': RoamlyColorSchemes.light,
      'dark': RoamlyColorSchemes.dark,
    }.entries) {
      test('${entry.key} foreground pairs meet WCAG AA contrast', () {
        final scheme = entry.value;

        expect(
          _contrastRatio(scheme.primary, scheme.onPrimary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(scheme.secondary, scheme.onSecondary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(scheme.tertiary, scheme.onTertiary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(scheme.surface, scheme.onSurface),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance < secondLuminance
      ? firstLuminance
      : secondLuminance;

  return (lighter + 0.05) / (darker + 0.05);
}
