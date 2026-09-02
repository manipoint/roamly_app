import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  group('RoamlyTheme', () {
    test('light theme uses the light semantic color scheme', () {
      final theme = RoamlyTheme.light;

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme, RoamlyColorSchemes.light);
      expect(theme.scaffoldBackgroundColor, RoamlyColors.background);
    });

    test('dark theme uses the dark semantic color scheme', () {
      final theme = RoamlyTheme.dark;

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme, RoamlyColorSchemes.dark);
      expect(theme.scaffoldBackgroundColor, RoamlyColors.deepInk);
    });

    test('both themes apply the Roamly typography contract', () {
      for (final theme in <ThemeData>[RoamlyTheme.light, RoamlyTheme.dark]) {
        _expectStyleMatches(
          theme.textTheme.headlineLarge!,
          RoamlyTypography.heading1,
          color: theme.colorScheme.onSurface,
        );
        _expectStyleMatches(
          theme.textTheme.bodyMedium!,
          RoamlyTypography.body,
          color: theme.colorScheme.onSurface,
        );
        _expectStyleMatches(
          theme.textTheme.labelLarge!,
          RoamlyTypography.button,
          color: theme.colorScheme.onSurface,
        );
      }
    });
  });
}

void _expectStyleMatches(
  TextStyle actual,
  TextStyle expected, {
  required Color color,
}) {
  expect(actual.fontFamily, expected.fontFamily);
  expect(actual.fontFamilyFallback, expected.fontFamilyFallback);
  expect(actual.fontSize, expected.fontSize);
  expect(actual.fontWeight, expected.fontWeight);
  expect(actual.letterSpacing, expected.letterSpacing);
  expect(actual.height, expected.height);
  expect(actual.color, color);
}
