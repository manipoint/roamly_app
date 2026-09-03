enum RoamlyWindowClass { compact, medium, expanded }

abstract final class RoamlyBreakpoints {
  static const double compactEnd = 600;
  static const double mediumEnd = 840;

  static RoamlyWindowClass classify(double width) {
    if (width.isNaN || width < 0) {
      throw ArgumentError.value(
        width,
        'width',
        'must be a non-negative number',
      );
    }

    if (width < compactEnd) {
      return RoamlyWindowClass.compact;
    }

    if (width < mediumEnd) {
      return RoamlyWindowClass.medium;
    }

    return RoamlyWindowClass.expanded;
  }
}
