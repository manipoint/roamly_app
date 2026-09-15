abstract final class HomeApiPaths {
  static const String discovery = 'home';
  static const String destinations = 'destinations';

  static String destinationDetail(String slug) {
    return '$destinations/$slug';
  }

  static String destinationPlaceDetail({
    required String destinationSlug,
    required String placeSlug,
  }) {
    return '$destinations/$destinationSlug/places/$placeSlug';
  }
}
