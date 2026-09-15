abstract final class HomeLayout {
  // Home: compact destination cards.
  static const int compactLoadingItemCount = 3;
  static const double compactPreferredWidth = 160;
  static const double compactMinWidth = 104;
  static const double compactMaxWidth = 160;
  static const double compactImageHeight = 136;

  // Home: wide suggested destination cards.
  static const double editorialMinWidth = 240;
  static const double editorialMaxWidth = 440;
  static const double editorialMinHeight = 156;
  // View all: responsive destination grid.
  static const double gridPadding = 16;
  static const double gridGap = 12;
  static const double gridMinCardWidth = 160;
  static const int gridMaxColumns = 4;
  static const double gridImageAspectRatio = 4 / 3;
  static const double heroImageAspectRatio = 1;

  static int gridColumnCount(double viewportWidth) {
    return gridColumnCountForAvailableWidth(viewportWidth - gridPadding * 2);
  }

  static int gridColumnCountForAvailableWidth(double availableWidth) {
    final safeWidth = availableWidth.clamp(0, double.infinity);
    return ((safeWidth + gridGap) / (gridMinCardWidth + gridGap))
        .floor()
        .clamp(1, gridMaxColumns)
        .toInt();
  }

  // Text limits used by rendering and height calculations.
  static const int compactTitleLines = 1;
  static const int compactSummaryLines = 1;
  static const int editorialTitleLines = 2;
  static const int editorialSummaryLines = 3;
  static const int gridTitleLines = 2;
  static const int gridSummaryLines = 2;
  static const int countryLines = 1;
}
