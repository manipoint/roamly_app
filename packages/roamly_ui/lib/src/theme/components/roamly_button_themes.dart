import 'package:flutter/material.dart';

import '../../foundations/radius/roamly_radii.dart';
import '../../foundations/spacing/roamly_spacing.dart';
import '../../foundations/typography/roamly_typography.dart';

abstract final class RoamlyButtonThemes {
  static FilledButtonThemeData filled(ColorScheme colors) {
    return FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: RoamlySpacing.space24,
            vertical: RoamlySpacing.space12,
          ),
        ),
        textStyle: const WidgetStatePropertyAll(RoamlyTypography.button),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: RoamlyRadii.medium),
        ),
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.onSurface.withValues(alpha: 0.12);
          }
          return colors.primary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.onSurface.withValues(alpha: 0.38);
          }
          return colors.onPrimary;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          return _overlayColor(states: states, color: colors.onPrimary);
        }),
      ),
    );
  }

  static OutlinedButtonThemeData outlined(ColorScheme colors) {
    return OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: RoamlySpacing.space24,
            vertical: RoamlySpacing.space12,
          ),
        ),
        textStyle: const WidgetStatePropertyAll(RoamlyTypography.button),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: RoamlyRadii.medium),
        ),
        elevation: const WidgetStatePropertyAll(0),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.onSurface.withValues(alpha: 0.38);
          }
          return colors.primary;
        }),
        side: WidgetStateBorderSide.resolveWith((states) {
          final color = states.contains(WidgetState.disabled)
              ? colors.onSurface.withValues(alpha: 0.12)
              : colors.primary;
          return BorderSide(color: color, width: 1.5);
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          return _overlayColor(states: states, color: colors.primary);
        }),
      ),
    );
  }

  static TextButtonThemeData text(ColorScheme colors) {
    return TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: RoamlySpacing.space16,
            vertical: RoamlySpacing.space12,
          ),
        ),
        textStyle: const WidgetStatePropertyAll(RoamlyTypography.button),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: RoamlyRadii.medium),
        ),
        elevation: const WidgetStatePropertyAll(0),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.onSurface.withValues(alpha: 0.38);
          }
          return colors.primary;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          return _overlayColor(states: states, color: colors.primary);
        }),
      ),
    );
  }

  static Color? _overlayColor({
    required Set<WidgetState> states,
    required Color color,
  }) {
    if (states.contains(WidgetState.pressed)) {
      return color.withValues(alpha: 0.12);
    }
    if (states.contains(WidgetState.focused)) {
      return color.withValues(alpha: 0.10);
    }
    if (states.contains(WidgetState.hovered)) {
      return color.withValues(alpha: 0.08);
    }

    return null;
  }
}
