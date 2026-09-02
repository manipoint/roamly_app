import 'package:flutter/material.dart';

abstract final class RoamlyTypography {
  static const String fontFamily = 'Inter';
  static const String fontPackage = 'roamly_ui';

  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    package: fontPackage,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    package: fontPackage,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: fontFamily,
    package: fontPackage,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    package: fontPackage,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    package: fontPackage,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    package: fontPackage,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
  );
  static const TextTheme textTheme = TextTheme(
    headlineLarge: heading1,
    headlineSmall: heading2,
    titleMedium: subtitle,
    bodyMedium: body,
    labelLarge: button,
    bodySmall: caption,
  );
}
