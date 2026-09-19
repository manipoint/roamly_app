/// Explicit, framework-independent value transformations shared by Roamly.
abstract final class RoamlyValueNormalizers {
  static String trimmed(String value) => value.trim();

  static String? optionalTrimmed(String? value) {
    if (value == null) return null;

    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static DateTime utc(DateTime value) => value.toUtc();
}
