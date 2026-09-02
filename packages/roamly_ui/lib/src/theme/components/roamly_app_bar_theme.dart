import 'package:flutter/material.dart';

import '../../foundations/typography/roamly_typography.dart';

abstract final class RoamlyAppBarTheme {
  static AppBarThemeData build(ColorScheme colors) {
    return AppBarThemeData(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colors.surface,
      foregroundColor: colors.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: RoamlyTypography.heading2.copyWith(
        color: colors.onSurface,
      ),
      iconTheme: IconThemeData(color: colors.onSurface, size: 24),
      actionsIconTheme: IconThemeData(color: colors.onSurface, size: 24),
    );
  }
}
