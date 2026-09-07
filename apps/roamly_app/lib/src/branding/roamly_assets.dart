/// Asset paths owned by the Roamly application brand.
abstract final class RoamlyAssets {
  static const String _brandingRoot = 'assets/branding';
  static const String _travelStyleRoot = 'assets/travel_style';

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

  /// Full-screen welcome background for light mode.
  static const String welcomeBackgroundLight =
      '$_brandingRoot/wellcom_splash.png';

  /// Full-screen welcome background for dark mode.
  static const String welcomeBackgroundDark =
      '$_brandingRoot/wellcome_splash_dark.png';
  static const String advanture = '$_travelStyleRoot/advanture.webp';
  static const String beaches = '$_travelStyleRoot/beaches.webp';
  static const String culture = '$_travelStyleRoot/culture.webp';
  static const String food = '$_travelStyleRoot/food.webp';
  static const String luxury = '$_travelStyleRoot/luxury.webp';
  static const String nature = '$_travelStyleRoot/nature.webp';

  /// Every runtime branding asset registered by the application.
  static const List<String> all = <String>[
    appIcon,
    logoOnLight,
    logoOnDark,
    logoWithTagline,
    splashBackgroundLight,
    splashBackgroundDark,
    welcomeBackgroundLight,
    welcomeBackgroundDark,
  ];
}
