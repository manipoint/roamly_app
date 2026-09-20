import 'package:roamly_core/roamly_core.dart';

/// Shared operational rules and limits for the Assistant feature.
abstract final class AssistantPolicy {
  // Request content.
  static const int minimumMessageLength = 1;
  static const int maximumMessageLength = 2000;
  static const int minimumLocaleLength = 2;
  static const int maximumLocaleLength = 35;

  // Realtime connection.
  static const Duration defaultReadyTimeout = Duration(seconds: 10);
  static const double maximumHeartbeatIntervalSeconds = 300;
  static const double maximumIdleTimeoutSeconds = 600;

  // Realtime payloads.
  static const int defaultMaximumIncomingMessageBytes = 1024 * 1024;
  static const int maximumConfigurableIncomingMessageBytes = 4 * 1024 * 1024;
  static const int maximumNegotiatedOutgoingMessageBytes = 1024 * 1024;

  // Local conversation history.
  static const int defaultConversationsLimit = 50;
  static const int maximumConversationsLimit = 100;
  static const int defaultMessagesLimit = 100;
  static const int maximumMessagesLimit = 200;

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
