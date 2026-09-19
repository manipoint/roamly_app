import 'package:roamly_core/roamly_core.dart';

/// Domain rules for requests submitted to the travel assistant.
abstract final class AssistantRequestPolicy {
  static const int minimumMessageLength = 1;
  static const int maximumMessageLength = 2000;
  static const int minimumLocaleLength = 2;
  static const int maximumLocaleLength = 35;

  static String normalizeMessage(String value) {
    final normalized = RoamlyValueNormalizers.trimmed(value);
    return RoamlyValueGuards.requireRuneLength(
      normalized,
      field: 'message',
      minimum: minimumMessageLength,
      maximum: maximumMessageLength,
    );
  }

  static String normalizeLocale(String value) {
    final normalized = RoamlyValueNormalizers.trimmed(value);
    return RoamlyValueGuards.requireRuneLength(
      normalized,
      field: 'locale',
      minimum: minimumLocaleLength,
      maximum: maximumLocaleLength,
    );
  }
}
