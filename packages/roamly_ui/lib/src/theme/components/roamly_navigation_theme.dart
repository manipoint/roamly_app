import 'package:flutter/material.dart';

import '../../foundations/typography/roamly_typography.dart';

abstract final class RoamlyNavigationTheme {
  static NavigationBarThemeData navigationBar(ColorScheme colors) {
    return NavigationBarThemeData(
      height: 72,
      elevation: 0,
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colors.primary.withValues(alpha: 0.12),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? colors.primary : colors.onSurfaceVariant,
          size: 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);

        return RoamlyTypography.caption.copyWith(
          color: selected ? colors.primary : colors.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        );
      }),
    );
  }

  static TabBarThemeData tabBar(ColorScheme colors) {
    return TabBarThemeData(
      indicatorColor: colors.primary,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      labelColor: colors.primary,
      unselectedLabelColor: colors.onSurfaceVariant,
      labelStyle: RoamlyTypography.button,
      unselectedLabelStyle: RoamlyTypography.body.copyWith(
        fontWeight: FontWeight.w500,
      ),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return colors.primary.withValues(alpha: 0.12);
        }

        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return colors.primary.withValues(alpha: 0.08);
        }

        return null;
      }),
    );
  }
}
