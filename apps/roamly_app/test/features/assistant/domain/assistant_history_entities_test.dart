import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_conversation.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message_delivery_state.dart';

void main() {
  const localConversationId = '00000000-0000-4000-8000-000000000001';
  const remoteConversationId = '00000000-0000-4000-8000-000000000002';
  const clientMessageId = '00000000-0000-4000-8000-000000000003';
  const assistantMessageId = '00000000-0000-4000-8000-000000000004';
  const itineraryId = '00000000-0000-4000-8000-000000000005';

  test('conversation keeps local and remote identity separate', () {
    final conversation = AssistantConversation(
      localId: localConversationId,
      remoteId: remoteConversationId,
      title: '  Lahore trip  ',
      createdAt: DateTime.parse('2026-09-18T13:00:00+05:00'),
      updatedAt: DateTime.parse('2026-09-18T14:00:00+05:00'),
    );

    expect(conversation.localId, localConversationId);
    expect(conversation.remoteId, remoteConversationId);
    expect(conversation.title, 'Lahore trip');
    expect(conversation.createdAt.isUtc, isTrue);
    expect(conversation.updatedAt.isUtc, isTrue);
  });

  test('conversation rejects an update before creation', () {
    expect(
      () => AssistantConversation(
        localId: localConversationId,
        createdAt: DateTime.utc(2026, 9, 18, 10),
        updatedAt: DateTime.utc(2026, 9, 18, 9),
      ),
      throwsArgumentError,
    );
  });

  test('assistant message preserves response formatting', () {
    final message = AssistantMessage(
      id: assistantMessageId,
      conversationLocalId: localConversationId,
      clientMessageId: clientMessageId,
      assistantMessageId: assistantMessageId,
      itineraryId: itineraryId,
      author: AssistantMessageAuthor.assistant,
      content: '  **Day 1**\nVisit the fort.\n',
      deliveryState: AssistantMessageDeliveryState.completed,
      createdAt: DateTime.utc(2026, 9, 18, 10),
      updatedAt: DateTime.utc(2026, 9, 18, 10),
    );

    expect(message.conversationLocalId, localConversationId);
    expect(message.content, '  **Day 1**\nVisit the fort.\n');
    expect(message.itineraryId, itineraryId);
  });

  test('author-specific identifiers cannot enter invalid states', () {
    expect(
      () => AssistantMessage(
        id: clientMessageId,
        conversationLocalId: localConversationId,
        clientMessageId: clientMessageId,
        assistantMessageId: assistantMessageId,
        author: AssistantMessageAuthor.user,
        content: 'Plan Lahore',
        deliveryState: AssistantMessageDeliveryState.pending,
        createdAt: DateTime.utc(2026, 9, 18),
        updatedAt: DateTime.utc(2026, 9, 18),
      ),
      throwsArgumentError,
    );

    expect(
      () => AssistantMessage(
        id: assistantMessageId,
        conversationLocalId: localConversationId,
        clientMessageId: clientMessageId,
        author: AssistantMessageAuthor.assistant,
        content: 'Your plan is ready.',
        deliveryState: AssistantMessageDeliveryState.completed,
        createdAt: DateTime.utc(2026, 9, 18),
        updatedAt: DateTime.utc(2026, 9, 18),
      ),
      throwsArgumentError,
    );
  });
}
