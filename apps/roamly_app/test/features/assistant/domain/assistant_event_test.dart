import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_event.dart';

void main() {
  const clientMessageId = '00000000-0000-4000-8000-000000000001';
  const conversationId = '00000000-0000-4000-8000-000000000002';
  const assistantMessageId = '00000000-0000-4000-8000-000000000003';

  test('accepted event validates correlation identifiers', () {
    expect(
      () => AssistantRequestAccepted(
        occurredAt: DateTime.utc(2026, 9, 18),
        clientMessageId: 'invalid',
        conversationId: conversationId,
      ),
      throwsArgumentError,
    );
  });

  test('completed event preserves formatted assistant content', () {
    final event = AssistantResponseCompleted(
      occurredAt: DateTime.parse('2026-09-18T13:00:00+05:00'),
      clientMessageId: clientMessageId,
      conversationId: conversationId,
      assistantMessageId: assistantMessageId,
      content: '  **Itinerary**\nDay one.\n',
      isDuplicate: false,
    );

    expect(event.content, '  **Itinerary**\nDay one.\n');
    expect(event.occurredAt, DateTime.parse('2026-09-18T08:00:00Z'));
  });

  test('blank content errors do not retain the rejected value', () {
    const rejected = '   \n';

    expect(
      () => AssistantResponseCompleted(
        occurredAt: DateTime.utc(2026, 9, 18),
        clientMessageId: clientMessageId,
        conversationId: conversationId,
        assistantMessageId: assistantMessageId,
        content: rejected,
        isDuplicate: false,
      ),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.toString(),
          'message',
          isNot(contains(rejected)),
        ),
      ),
    );
  });
}
