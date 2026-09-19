import 'roamly_value_validators.dart';

/// Enforces trusted application and domain construction boundaries.
///
/// Errors intentionally omit rejected values so sensitive content cannot leak
/// into logs or crash reports.
abstract final class RoamlyValueGuards {
  static String requireUuid(String value, {required String field}) {
    if (!RoamlyValueValidators.isValidUuid(value)) {
      throw ArgumentError('$field must be a valid UUID.');
    }

    return value;
  }

  static String? requireOptionalUuid(String? value, {required String field}) {
    if (value == null) return null;

    return requireUuid(value, field: field);
  }

  /// Validates text without changing its formatting.
  static String requireNonBlank(String value, {required String field}) {
    if (!RoamlyValueValidators.isNonBlank(value)) {
      throw ArgumentError('$field must not be empty or blank.');
    }

    return value;
  }

  static String requireRuneLength(
    String value, {
    required String field,
    required int minimum,
    required int maximum,
  }) {
    if (!RoamlyValueValidators.hasRuneLength(
      value,
      minimum: minimum,
      maximum: maximum,
    )) {
      throw ArgumentError(
        '$field must contain between $minimum and $maximum characters.',
      );
    }

    return value;
  }

  static DateTime requireNotBefore({
    required DateTime value,
    required DateTime minimum,
    required String field,
  }) {
    if (!RoamlyValueValidators.isNotBefore(value, minimum)) {
      throw ArgumentError('$field has an invalid chronological value.');
    }

    return value;
  }
}
