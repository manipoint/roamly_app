import 'package:flutter/material.dart';

import '../../foundations/radius/roamly_radii.dart';
import '../../foundations/spacing/roamly_spacing.dart';
import '../../foundations/typography/roamly_typography.dart';

abstract final class RoamlyInputTheme {
  static InputDecorationThemeData build(ColorScheme colors) {
    final defaultBorder = OutlineInputBorder(
      borderRadius: RoamlyRadii.medium,
      borderSide: BorderSide(color: colors.outlineVariant),
    );
    return InputDecorationThemeData(
      filled: true,
      fillColor: colors.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: RoamlySpacing.space16,
        vertical: RoamlySpacing.space16,
      ),
      hintStyle: RoamlyTypography.body.copyWith(color: colors.onSurfaceVariant),
      labelStyle: RoamlyTypography.body.copyWith(
        color: colors.onSurfaceVariant,
      ),
      floatingLabelStyle: RoamlyTypography.body.copyWith(color: colors.primary),
      errorStyle: RoamlyTypography.caption.copyWith(color: colors.error),
      prefixIconColor: colors.onSurfaceVariant,
      suffixIconColor: colors.onSurfaceVariant,
      border: defaultBorder,
      enabledBorder: defaultBorder,
      disabledBorder: defaultBorder.copyWith(
        borderSide: BorderSide(color: colors.onSurface.withValues(alpha: 0.12)),
      ),
      focusedBorder: defaultBorder.copyWith(
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      errorBorder: defaultBorder.copyWith(
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: defaultBorder.copyWith(
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
    );
  }
}
