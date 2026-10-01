import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message_delivery_state.dart';
import 'package:roamly_app/src/features/assistant/presentation/widgets/assistant_message_bubble.dart';
import 'package:roamly_app/src/localization/app_strings.dart';

void main() {
  for (final code in [
    null,
    'response.providerError',
    'rejected.conversationNotFound',
    'future.code',
  ]) {
    testWidgets('failed message shows safe explanation for $code', (
      tester,
    ) async {
      final message = AssistantMessage(
        id: '10000000-0000-4000-8000-000000000001',
        conversationLocalId: '10000000-0000-4000-8000-000000000002',
        clientMessageId: '10000000-0000-4000-8000-000000000003',
        author: AssistantMessageAuthor.user,
        content: 'UK',
        deliveryState: AssistantMessageDeliveryState.failed,
        failureCode: code,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 800),
                textScaler: TextScaler.linear(2),
              ),
              child: SingleChildScrollView(
                child: AssistantMessageBubble(message: message),
              ),
            ),
          ),
        ),
      );
      expect(
        find.text(AppStrings.assistantFailureReason(code)),
        findsOneWidget,
      );
      expect(find.text('UK'), findsOneWidget);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.tap(find.byTooltip(AppStrings.assistantCopyMessage));
      await tester.pump();
      expect(copied, 'UK');
      expect(find.text(AppStrings.assistantMessageCopied), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
