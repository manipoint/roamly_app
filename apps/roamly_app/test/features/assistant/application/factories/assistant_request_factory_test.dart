import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/application/factories/assistant_request_factory.dart';

void main() {
  const generatedConversationId = '00000000-0000-4000-8000-000000000001';
  const generatedClientMessageId = '00000000-0000-4000-8000-000000000002';
  const existingConversationLocalId = '00000000-0000-4000-8000-000000000003';
  const remoteConversationId = '00000000-0000-4000-8000-000000000004';
  const tripId = '00000000-0000-4000-8000-000000000005';
  final timestamp = DateTime.parse('2026-09-22T13:00:00+05:00');

  test('generates conversation and client IDs for a new conversation', () {
    final generatedIds = <String>[
      generatedConversationId,
      generatedClientMessageId,
    ];
    var index = 0;
    final factory = AssistantRequestFactory(
      idGenerator: () => generatedIds[index++],
      clock: () => timestamp,
    );

    final request = factory.create(
      message: '  Plan Lahore  ',
      locale: '  en-PK  ',
      tripId: tripId,
    );

    expect(request.conversationLocalId, generatedConversationId);
    expect(request.clientMessageId, generatedClientMessageId);
    expect(request.conversationId, isNull);
    expect(request.tripId, tripId);
    expect(request.message, 'Plan Lahore');
    expect(request.locale, 'en-PK');
    expect(request.createdAt, DateTime.utc(2026, 9, 22, 8));
    expect(index, 2);
  });

  test('reuses an existing conversation and generates only the request ID', () {
    var generationCalls = 0;
    final factory = AssistantRequestFactory(
      idGenerator: () {
        generationCalls++;
        return generatedClientMessageId;
      },
      clock: () => timestamp,
    );

    final request = factory.create(
      conversationLocalId: existingConversationLocalId,
      conversationId: remoteConversationId,
      message: 'Continue planning',
    );

    expect(request.conversationLocalId, existingConversationLocalId);
    expect(request.conversationId, remoteConversationId);
    expect(request.clientMessageId, generatedClientMessageId);
    expect(generationCalls, 1);
  });

  test('rejects an invalid generated identifier', () {
    final factory = AssistantRequestFactory(
      idGenerator: () => 'invalid-id',
      clock: () => timestamp,
    );

    expect(() => factory.create(message: 'Plan Lahore'), throwsArgumentError);
  });
}
