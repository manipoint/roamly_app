/// Relative Assistant endpoints resolved against the configured `/api/v1/` URL.
abstract final class AssistantApiPaths {
  static const String conversations = 'conversations';

  static String conversation(String conversationId) {
    return '$conversations/${Uri.encodeComponent(conversationId)}';
  }
}
