enum RoamlyWindowClass { compact, medium, expanded }

abstract final class RoamlyBreakpoints {
  static const double compactEnd = 600;
  static const double mediumEnd = 840;

  static RoamlyWindowClass claaify(double width) {
    if (width < compactEnd) {
      return RoamlyWindowClass.compact;
    }
    if (width < mediumEnd) {
      return RoamlyWindowClass.medium;
    }
    return RoamlyWindowClass.expanded;
  }
}
