abstract interface class AssistantRemoteDataSource {
  Future<void> deleteConversation({required String conversationId});
}
