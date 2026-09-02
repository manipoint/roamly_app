import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_ui/roamly_ui.dart';
import 'package:roamly_ui/src/theme/components/roamly_app_bar_theme.dart';
import 'package:roamly_ui/src/theme/components/roamly_button_themes.dart';
import 'package:roamly_ui/src/theme/components/roamly_input_theme.dart';
import 'package:roamly_ui/src/theme/components/roamly_navigation_theme.dart';

void main() {
  final colors = RoamlyColorSchemes.light;

  group('RoamlyAppBarTheme', () {
    test('uses semantic surface colors and zero elevation', () {
      final theme = RoamlyAppBarTheme.build(colors);

      expect(theme.backgroundColor, colors.surface);
      expect(theme.foregroundColor, colors.onSurface);
      expect(theme.surfaceTintColor, Colors.transparent);
      expect(theme.elevation, 0);
      expect(theme.scrolledUnderElevation, 0);
      expect(
        theme.titleTextStyle?.fontFamily,
        'packages/${RoamlyTypography.fontPackage}/${RoamlyTypography.fontFamily}',
      );
      expect(theme.titleTextStyle?.color, colors.onSurface);
    });
  });

  group('RoamlyButtonThemes', () {
    test('filled button resolves enabled and disabled colors', () {
      final style = RoamlyButtonThemes.filled(colors).style!;

      expect(style.minimumSize?.resolve({}), const Size(0, 52));
      expect(style.backgroundColor?.resolve({}), colors.primary);
      expect(style.foregroundColor?.resolve({}), colors.onPrimary);
      expect(
        style.backgroundColor?.resolve({WidgetState.disabled}),
        colors.onSurface.withValues(alpha: 0.12),
      );
      expect(
        style.foregroundColor?.resolve({WidgetState.disabled}),
        colors.onSurface.withValues(alpha: 0.38),
      );
      expect(
        style.overlayColor?.resolve({WidgetState.pressed}),
        colors.onPrimary.withValues(alpha: 0.12),
      );
    });

    test('outlined button resolves its border for each state', () {
      final style = RoamlyButtonThemes.outlined(colors).style!;

      expect(style.minimumSize?.resolve({}), const Size(0, 52));
      expect(
        style.side?.resolve({}),
        BorderSide(color: colors.primary, width: 1.5),
      );
      expect(
        style.side?.resolve({WidgetState.disabled}),
        BorderSide(color: colors.onSurface.withValues(alpha: 0.12), width: 1.5),
      );
    });

    test('text button retains a minimum accessible height', () {
      final style = RoamlyButtonThemes.text(colors).style!;

      expect(style.minimumSize?.resolve({}), const Size(0, 48));
      expect(style.foregroundColor?.resolve({}), colors.primary);
    });
  });

  group('RoamlyInputTheme', () {
    test('defines enabled, focused, disabled, and error borders', () {
      final theme = RoamlyInputTheme.build(colors);
      final enabled = theme.enabledBorder! as OutlineInputBorder;
      final focused = theme.focusedBorder! as OutlineInputBorder;
      final disabled = theme.disabledBorder! as OutlineInputBorder;
      final error = theme.errorBorder! as OutlineInputBorder;

      expect(theme.filled, isTrue);
      expect(theme.fillColor, colors.surfaceContainerLowest);
      expect(enabled.borderSide.color, colors.outlineVariant);
      expect(focused.borderSide, BorderSide(color: colors.primary, width: 2));
      expect(
        disabled.borderSide.color,
        colors.onSurface.withValues(alpha: 0.12),
      );
      expect(error.borderSide.color, colors.error);
    });
  });

  group('RoamlyNavigationTheme', () {
    test('navigation bar resolves selected and unselected colors', () {
      final theme = RoamlyNavigationTheme.navigationBar(colors);

      expect(theme.height, 72);
      expect(theme.backgroundColor, colors.surface);
      expect(theme.iconTheme?.resolve({})?.color, colors.onSurfaceVariant);
      expect(
        theme.iconTheme?.resolve({WidgetState.selected})?.color,
        colors.primary,
      );
    });

    test('tab bar uses semantic selected and unselected colors', () {
      final theme = RoamlyNavigationTheme.tabBar(colors);

      expect(theme.indicatorColor, colors.primary);
      expect(theme.labelColor, colors.primary);
      expect(theme.unselectedLabelColor, colors.onSurfaceVariant);
      expect(theme.dividerColor, Colors.transparent);
    });
  });
}
