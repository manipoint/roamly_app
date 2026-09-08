/// Shared input limits for canonical location resolution.
///
/// These constraints mirror the backend contract and are reused by the
/// repository and transport boundary to avoid divergent validation rules.
abstract final class LocationResolutionPolicy {
  static const int minimumQueryLength = 2;
  static const int maximumQueryLength = 120;
  static const int maximumResultLimit = 5;
}
