import 'package:flutter/material.dart';

import '../foundations/typography/roamly_typography.dart';
import 'components/roamly_app_bar_theme.dart';
import 'components/roamly_button_themes.dart';
import 'components/roamly_input_theme.dart';
import 'components/roamly_navigation_theme.dart';
import 'roamly_color_schemes.dart';

abstract final class RoamlyTheme {
  static final ThemeData light = _build(RoamlyColorSchemes.light);
  static final ThemeData dark = _build(RoamlyColorSchemes.dark);

  static ThemeData _build(ColorScheme colors) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      fontFamily: RoamlyTypography.fontFamily,
      package: RoamlyTypography.fontPackage,
    );
    final textTheme = baseTheme.textTheme
        .merge(RoamlyTypography.textTheme)
        .apply(bodyColor: colors.onSurface, displayColor: colors.onSurface);
    return baseTheme.copyWith(
      scaffoldBackgroundColor: colors.surface,
      textTheme: textTheme,
      appBarTheme: RoamlyAppBarTheme.build(colors),
      filledButtonTheme: RoamlyButtonThemes.filled(colors),
      outlinedButtonTheme: RoamlyButtonThemes.outlined(colors),
      textButtonTheme: RoamlyButtonThemes.text(colors),
      inputDecorationTheme: RoamlyInputTheme.build(colors),
      navigationBarTheme: RoamlyNavigationTheme.navigationBar(colors),
      tabBarTheme: RoamlyNavigationTheme.tabBar(colors),
    );
  }
}
