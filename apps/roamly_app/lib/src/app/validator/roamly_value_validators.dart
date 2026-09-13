/// Pure validation rules shared by transport models and domain boundaries.
///
/// These methods do not normalize input or return localized presentation text.
abstract final class RoamlyValueValidators {
  static const int uuidLength = 36;
  static const int minimumSlugLength = 2;
  static const int maximumSlugLength = 120;
  static const int countryCodeLength = 2;

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-'
    r'[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{12}$',
  );
  static final RegExp _slugPattern = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
  static final RegExp _countryCodePattern = RegExp(r'^[A-Z]{2}$');

  static bool isValidUuid(String value) =>
      value.length == uuidLength && _uuidPattern.hasMatch(value);

  static bool isValidSlug(String value) =>
      value.length >= minimumSlugLength &&
      value.length <= maximumSlugLength &&
      _slugPattern.hasMatch(value);

  static bool isValidCountryCode(String value) =>
      value.length == countryCodeLength && _countryCodePattern.hasMatch(value);
}
