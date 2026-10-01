import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_networking/roamly_networking.dart';

import '../api/assistant_api_paths.dart';
import 'assistant_remote_data_source.dart';

/// Performs authenticated Assistant API operations.
final class ApiAssistantRemoteDataSource implements AssistantRemoteDataSource {
  const ApiAssistantRemoteDataSource({required ApiClient authenticatedClient})
    : _client = authenticatedClient;

  final ApiClient _client;

  @override
  Future<void> deleteConversation({required String conversationId}) async {
    final validatedId = RoamlyValueGuards.requireUuid(
      conversationId,
      field: 'conversationId',
    );
    await _client.delete(AssistantApiPaths.conversation(validatedId));
  }
}
