/// Stable route names used for type-safe application navigation.
abstract final class AppRouteNames {
  static const String root = 'root';
  static const String welcome = 'welcome';
  static const String signIn = 'sign-in';
  static const String register = 'register';
  static const String home = 'home';
  static const String destinationDetail = 'destination-detail';
  static const String destinationPlaceDetail = 'destination-place-detail';
  static const String trips = 'trips';
  static const String assistant = 'assistant';
  static const String saved = 'saved';
  static const String profile = 'profile';
}

/// URL paths owned by the Roamly application.
abstract final class AppRoutePaths {
  static const String root = '/';
  static const String welcome = '/welcome';
  static const String signIn = '/sign-in';
  static const String register = '/register';
  static const String home = '/home';
  static const String destinationDetail = 'destinations/:slug';
  static const String destinationPlaceDetail = 'places/:placeSlug';
  static const String trips = '/trips';
  static const String assistant = '/assistant';
  static const String saved = '/saved';
  static const String profile = '/profile';
}
