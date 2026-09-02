/// Asset paths owned by the Roamly application brand.
abstract final class RoamlyAssets {
  static const String _brandingRoot = 'assets/branding';

  /// Source image used to generate platform application icons.
  static const String appIcon = '$_brandingRoot/roamly_app_icon.png';

  /// Roamly logo intended for light surfaces.
  static const String logoOnLight = '$_brandingRoot/roamly_logo_on_light.png';

  /// Roamly logo intended for dark surfaces.
  static const String logoOnDark = '$_brandingRoot/roamly_logo_on_dark.png';

  /// Full logo lockup including the brand tagline.
  static const String logoWithTagline =
      '$_brandingRoot/roamly_logo_with_tagline.png';

  /// Light-mode splash background.
  static const String splashBackgroundLight =
      '$_brandingRoot/roamly_splash_background_light.png';

  /// Dark-mode splash background.
  static const String splashBackgroundDark =
      '$_brandingRoot/roamly_splash_background_dark.png';

  /// Every runtime branding asset registered by the application.
  static const List<String> all = <String>[
    appIcon,
    logoOnLight,
    logoOnDark,
    logoWithTagline,
    splashBackgroundLight,
    splashBackgroundDark,
  ];
}
