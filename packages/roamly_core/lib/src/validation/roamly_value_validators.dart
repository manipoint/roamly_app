/// Pure, framework-independent validation rules shared across Roamly.
///
/// These methods never normalize values or throw for invalid user data.
abstract final class RoamlyValueValidators {
  static const int uuidLength = 36;
  static const int minimumSlugLength = 2;
  static const int maximumSlugLength = 120;
  static const int countryCodeLength = 2;
  static const int iataCodeLength = 3;
  static const int minimumAmountLength = 1;
  static const int maximumAmountLength = 100;

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-'
    r'[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{12}$',
  );
  static final RegExp _slugPattern = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
  static final RegExp _countryCodePattern = RegExp(r'^[A-Z]{2}$');
  static final RegExp _iataCodePattern = RegExp(r'^[A-Z]{3}$');
  static final RegExp _amountPattern = RegExp(
    r'^(?:0|[1-9][0-9]*)(?:\.[0-9]+)?$',
  );

  static bool isValidUuid(String value) =>
      value.length == uuidLength && _uuidPattern.hasMatch(value);

  static bool isValidSlug(String value) =>
      value.length >= minimumSlugLength &&
      value.length <= maximumSlugLength &&
      _slugPattern.hasMatch(value);

  static bool isValidCountryCode(String value) =>
      value.length == countryCodeLength && _countryCodePattern.hasMatch(value);

  static bool isValidIataCode(String value) =>
      value.length == iataCodeLength && _iataCodePattern.hasMatch(value);
  static bool isValidCurrencyCode(String value) =>
      value.length == iataCodeLength && _iataCodePattern.hasMatch(value);

  static bool isValidAmountPattern(String value) =>
      value.length >= minimumAmountLength &&
      value.length <= maximumAmountLength &&
      _amountPattern.hasMatch(value);

  static bool isNonBlank(String value) => value.trim().isNotEmpty;

  static bool hasRuneLength(
    String value, {
    required int minimum,
    required int maximum,
  }) {
    if (minimum < 0 || maximum < minimum) return false;

    final length = value.runes.length;
    return length >= minimum && length <= maximum;
  }

  static bool isNotBefore(DateTime value, DateTime minimum) =>
      !value.isBefore(minimum);
      
  static bool isValidDateParts({
    required int year,
    required int month,
    required int day,
  }) {
    final date = DateTime.utc(year, month, day);

    return date.year == year && date.month == month && date.day == day;
  }
}
