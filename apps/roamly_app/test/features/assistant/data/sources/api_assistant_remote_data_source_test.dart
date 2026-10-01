import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/data/sources/api_assistant_remote_data_source.dart';
import 'package:roamly_networking/roamly_networking.dart';

final class _RecordingApiClient implements ApiClient {
  final deletedPaths = <String>[];

  @override
  Future<Object?> delete(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  }) async {
    deletedPaths.add(path);
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('deletes a remote conversation using its UUID path segment', () async {
    final client = _RecordingApiClient();
    final source = ApiAssistantRemoteDataSource(authenticatedClient: client);

    await source.deleteConversation(
      conversationId: '10000000-0000-4000-8000-000000000001',
    );

    expect(client.deletedPaths, [
      'conversations/10000000-0000-4000-8000-000000000001',
    ]);
  });

  test(
    'rejects an invalid remote conversation ID before making a request',
    () async {
      final client = _RecordingApiClient();
      final source = ApiAssistantRemoteDataSource(authenticatedClient: client);

      await expectLater(
        source.deleteConversation(conversationId: 'not-a-uuid'),
        throwsArgumentError,
      );
      expect(client.deletedPaths, isEmpty);
    },
  );
}
