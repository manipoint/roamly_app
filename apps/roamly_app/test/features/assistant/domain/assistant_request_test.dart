import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_request.dart';
import 'package:roamly_app/src/features/assistant/domain/policies/assistant_request_policy.dart';

void main() {
  const clientMessageId = '00000000-0000-4000-8000-000000000001';

  test('normalizes request text, locale, and timestamp', () {
    final request = AssistantRequest(
      clientMessageId: clientMessageId,
      message: '  Plan Lahore  ',
      locale: '  en-PK  ',
      createdAt: DateTime.parse('2026-09-18T13:00:00+05:00'),
    );

    expect(request.message, 'Plan Lahore');
    expect(request.locale, 'en-PK');
    expect(request.createdAt, DateTime.parse('2026-09-18T08:00:00Z'));
  });

  test('enforces request policy boundaries without exposing content', () {
    final oversized = List.filled(
      AssistantRequestPolicy.maximumMessageLength + 1,
      'sensitive',
    ).join();

    expect(
      () => AssistantRequest(
        clientMessageId: clientMessageId,
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
        clientMessageId: 'invalid',
        message: 'Plan Lahore',
        createdAt: DateTime.utc(2026, 9, 18),
      ),
      throwsArgumentError,
    );
  });
}
