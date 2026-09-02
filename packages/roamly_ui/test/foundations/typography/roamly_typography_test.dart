import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RoamlyTypography', () {
    test('uses the Inter font exported by roamly_ui', () {
      const styles = [
        RoamlyTypography.heading1,
        RoamlyTypography.heading2,
        RoamlyTypography.subtitle,
        RoamlyTypography.body,
        RoamlyTypography.button,
        RoamlyTypography.caption,
      ];

      expect(RoamlyTypography.fontFamily, 'Inter');
      expect(RoamlyTypography.fontPackage, 'roamly_ui');
      expect(
        styles.every((style) => style.fontFamily == 'packages/roamly_ui/Inter'),
        isTrue,
      );
    });

    test('matches the approved typography metrics', () {
      _expectStyle(
        RoamlyTypography.heading1,
        size: 32,
        lineHeight: 40 / 32,
        weight: FontWeight.w700,
        letterSpacing: -0.5,
      );
      _expectStyle(
        RoamlyTypography.heading2,
        size: 20,
        lineHeight: 28 / 20,
        weight: FontWeight.w600,
        letterSpacing: -0.2,
      );
      _expectStyle(
        RoamlyTypography.subtitle,
        size: 16,
        lineHeight: 24 / 16,
        weight: FontWeight.w500,
      );
      _expectStyle(
        RoamlyTypography.body,
        size: 14,
        lineHeight: 20 / 14,
        weight: FontWeight.w400,
      );
      _expectStyle(
        RoamlyTypography.button,
        size: 14,
        lineHeight: 20 / 14,
        weight: FontWeight.w600,
      );
      _expectStyle(
        RoamlyTypography.caption,
        size: 12,
        lineHeight: 16 / 12,
        weight: FontWeight.w400,
      );
    });

    test('maps styles to their semantic TextTheme roles', () {
      expect(
        RoamlyTypography.textTheme.headlineLarge,
        RoamlyTypography.heading1,
      );
      expect(
        RoamlyTypography.textTheme.headlineSmall,
        RoamlyTypography.heading2,
      );
      expect(RoamlyTypography.textTheme.titleMedium, RoamlyTypography.subtitle);
      expect(RoamlyTypography.textTheme.bodyMedium, RoamlyTypography.body);
      expect(RoamlyTypography.textTheme.labelLarge, RoamlyTypography.button);
      expect(RoamlyTypography.textTheme.bodySmall, RoamlyTypography.caption);
    });

    test('bundles the Inter variable font', () async {
      final font = await rootBundle.load(
        'packages/roamly_ui/assets/fonts/Inter-Variable.ttf',
      );

      expect(font.lengthInBytes, greaterThan(0));
    });
  });
}

void _expectStyle(
  TextStyle style, {
  required double size,
  required double lineHeight,
  required FontWeight weight,
  double? letterSpacing,
}) {
  expect(style.fontSize, size);
  expect(style.height, lineHeight);
  expect(style.fontWeight, weight);
  expect(style.letterSpacing, letterSpacing);
}
