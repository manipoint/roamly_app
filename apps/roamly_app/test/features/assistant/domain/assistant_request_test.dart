import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_request.dart';
import 'package:roamly_app/src/features/assistant/domain/policies/assistant_policy.dart';

void main() {
  const clientMessageId = '00000000-0000-4000-8000-000000000001';
  const localConversationId = '00000000-0000-4000-8000-000000000002';

  test('normalizes request text, locale, and timestamp', () {
    final request = AssistantRequest(
      clientMessageId: clientMessageId,
      conversationLocalId: localConversationId,
      message: '  Plan Lahore  ',
      locale: '  en-PK  ',
      createdAt: DateTime.parse('2026-09-18T13:00:00+05:00'),
    );

    expect(request.message, 'Plan Lahore');
    expect(request.locale, 'en-PK');
    expect(request.createdAt, DateTime.parse('2026-09-18T08:00:00Z'));
    expect(request.conversationLocalId, localConversationId);
  });

  test('enforces request policy boundaries without exposing content', () {
    final oversized = List.filled(
      AssistantPolicy.maximumMessageLength + 1,
      'sensitive',
    ).join();

    expect(
      () => AssistantRequest(
        clientMessageId: clientMessageId,
        conversationLocalId: localConversationId,
        message: oversized,
        createdAt: DateTime.utc(2026, 9, 18),
      ),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.toString(),
          'message',
          isNot(contains('sensitive')),
        ),
      ),
    );
  });

  test('rejects malformed correlation IDs', () {
    expect(
      () => AssistantRequest(
        conversationLocalId: localConversationId,
        clientMessageId: 'invalid',
        message: 'Plan Lahore',
        createdAt: DateTime.utc(2026, 9, 18),
      ),
      throwsArgumentError,
    );

    expect(
      () => AssistantRequest(
        conversationLocalId: 'invalid',
        clientMessageId: clientMessageId,
        message: 'Plan Lahore',
        createdAt: DateTime.utc(2026, 9, 18),
      ),
      throwsArgumentError,
    );
  });
}
