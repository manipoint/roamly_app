/// Dependency-free equality helpers for immutable domain collections.
abstract final class CollectionEquality {
  /// Compares two lists while preserving rank or presentation order.
  static bool ordered<T>(List<T> left, List<T> right) {
    if (identical(left, right)) {
      return true;
    }
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  /// Compares sets whose insertion order has no business meaning.
  static bool unordered<T>(Set<T> left, Set<T> right) {
    return identical(left, right) ||
        left.length == right.length && left.containsAll(right);
  }
}
