import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/domain/policies/assistant_policy.dart';
import 'package:roamly_app/src/features/assistant/presentation/widgets/assistant_message_composer.dart';

const _fieldKey = ValueKey<String>('assistant-message-field');
const _sendButtonKey = ValueKey<String>('assistant-send-button');

Widget _app({
  required AssistantMessageSubmitCallback onSubmit,
  bool isSending = false,
  bool enabled = true,
  String? errorText,
}) {
  return MaterialApp(
    home: Scaffold(
      body: AssistantMessageComposer(
        onSubmit: onSubmit,
        isSending: isSending,
        enabled: enabled,
        errorText: errorText,
      ),
    ),
  );
}

void main() {
  testWidgets('keeps send disabled for empty and whitespace-only input', (
    tester,
  ) async {
    await tester.pumpWidget(_app(onSubmit: (_) async => true));

    IconButton sendButton() => tester.widget(find.byKey(_sendButtonKey));

    expect(sendButton().onPressed, isNull);

    await tester.enterText(find.byKey(_fieldKey), '   ');
    await tester.pump();

    expect(sendButton().onPressed, isNull);
  });

  testWidgets('submits trimmed content and clears it after success', (
    tester,
  ) async {
    String? submittedMessage;
    await tester.pumpWidget(
      _app(
        onSubmit: (message) async {
          submittedMessage = message;
          return true;
        },
      ),
    );

    await tester.enterText(find.byKey(_fieldKey), '  Plan Lahore  ');
    await tester.pump();
    await tester.tap(find.byKey(_sendButtonKey));
    await tester.pumpAndSettle();

    expect(submittedMessage, 'Plan Lahore');
    expect(
      tester.widget<TextField>(find.byKey(_fieldKey)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('preserves the draft when submission fails', (tester) async {
    await tester.pumpWidget(_app(onSubmit: (_) async => false));

    await tester.enterText(find.byKey(_fieldKey), '  Keep this draft  ');
    await tester.pump();
    await tester.tap(find.byKey(_sendButtonKey));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byKey(_fieldKey)).controller!.text,
      '  Keep this draft  ',
    );
  });

  testWidgets('blocks duplicate submission while the first is pending', (
    tester,
  ) async {
    final completer = Completer<bool>();
    var submitCalls = 0;
    await tester.pumpWidget(
      _app(
        onSubmit: (_) {
          submitCalls++;
          return completer.future;
        },
      ),
    );

    await tester.enterText(find.byKey(_fieldKey), 'Plan a trip');
    await tester.pump();
    await tester.tap(find.byKey(_sendButtonKey));
    await tester.pump();

    expect(submitCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(_fieldKey)).readOnly, isTrue);

    completer.complete(true);
    await tester.pumpAndSettle();

    expect(submitCalls, 1);
  });

  testWidgets('shows external sending state without disabling the field', (
    tester,
  ) async {
    await tester.pumpWidget(_app(onSubmit: (_) async => true, isSending: true));

    final field = tester.widget<TextField>(find.byKey(_fieldKey));
    expect(field.enabled, isTrue);
    expect(field.readOnly, isTrue);
    expect(find.byKey(_sendButtonKey), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('enforces the domain message length limit', (tester) async {
    await tester.pumpWidget(_app(onSubmit: (_) async => true));

    await tester.enterText(
      find.byKey(_fieldKey),
      'a' * (AssistantPolicy.maximumMessageLength + 1),
    );
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byKey(_fieldKey)).controller!.text.length,
      AssistantPolicy.maximumMessageLength,
    );
  });
}
