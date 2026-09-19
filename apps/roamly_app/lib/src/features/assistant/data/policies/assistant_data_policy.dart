/// Technical safety limits for the Assistant WebSocket protocol.
abstract final class AssistantDataPolicy {
  static const Duration defaultReadyTimeout = Duration(seconds: 10);

  static const int defaultMaximumIncomingMessageBytes = 1024 * 1024;
  static const int maximumConfigurableIncomingMessageBytes = 4 * 1024 * 1024;
  static const int maximumNegotiatedOutgoingMessageBytes = 1024 * 1024;

  static const double maximumHeartbeatIntervalSeconds = 300;
  static const double maximumIdleTimeoutSeconds = 600;
  
  static const int defaultConversationsLimit = 50;
  static const int defaultMessagesLimit = 100;


}
