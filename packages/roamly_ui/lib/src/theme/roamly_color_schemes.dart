import 'package:flutter/material.dart';
import '../foundations/colors/roamly_colors.dart';

abstract final class RoamlyColorSchemes {
  static final ColorScheme light =
      ColorScheme.fromSeed(
        seedColor: RoamlyColors.blue,
        brightness: Brightness.light,
      ).copyWith(
        primary: RoamlyColors.blue,
        onPrimary: RoamlyColors.white,
        secondary: RoamlyColors.indigo,
        tertiary: RoamlyColors.teal,
        surface: RoamlyColors.background,
        onSurface: RoamlyColors.deepInk,
        onSecondary: RoamlyColors.white,
        onTertiary: RoamlyColors.deepInk,
      );
  static final ColorScheme dark =
      ColorScheme.fromSeed(
        seedColor: RoamlyColors.indigo,
        brightness: Brightness.dark,
      ).copyWith(
        primary: RoamlyColors.indigo,
        onPrimary: RoamlyColors.white,
        secondary: RoamlyColors.cyan,
        tertiary: RoamlyColors.teal,
        surface: RoamlyColors.deepInk,
        onSurface: RoamlyColors.white,
        onSecondary: RoamlyColors.deepInk,
        onTertiary: RoamlyColors.deepInk,
      );
}
