/// Shared limits matching the backend Home endpoint contract.
abstract final class HomeDiscoveryPolicy {
  static const int minimumSectionLimit = 1;
  static const int maximumSectionLimit = 6;
  static const int defaultSectionLimit = maximumSectionLimit;

  static bool isValidLimit(int limit) {
    return limit >= minimumSectionLimit && limit <= maximumSectionLimit;
  }
}
