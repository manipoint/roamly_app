import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  testWidgets('renders the prompt and action label', (tester) async {
    await _pumpInlineAction(
      tester,
      const RoamlyInlineAction(
        prompt: 'Already have an account?',
        actionLabel: 'Sign in',
        onPressed: null,
      ),
    );

    expect(find.text('Already have an account?'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(RoamlyButton), findsOneWidget);
  });

  testWidgets('invokes the supplied action callback', (tester) async {
    var tapCount = 0;
    await _pumpInlineAction(
      tester,
      RoamlyInlineAction(
        prompt: 'New here?',
        actionLabel: 'Create account',
        onPressed: () => tapCount++,
      ),
    );

    await tester.tap(find.text('Create account'));

    expect(tapCount, 1);
  });

  testWidgets('disables the action when callback is null', (tester) async {
    await _pumpInlineAction(
      tester,
      const RoamlyInlineAction(
        prompt: 'Already registered?',
        actionLabel: 'Sign in',
        onPressed: null,
      ),
    );

    final button = tester.widget<TextButton>(find.byType(TextButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('forwards the optional action key', (tester) async {
    await _pumpInlineAction(
      tester,
      const RoamlyInlineAction(
        prompt: 'Already registered?',
        actionLabel: 'Sign in',
        actionKey: ValueKey<String>('sign-in-action'),
        onPressed: null,
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('sign-in-action')),
      findsOneWidget,
    );
  });

  testWidgets('wraps without overflow on a narrow screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(240, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpInlineAction(
      tester,
      const RoamlyInlineAction(
        prompt: 'Already have a Roamly account?',
        actionLabel: 'Sign in now',
        onPressed: null,
      ),
      textScaler: const TextScaler.linear(2),
    );

    expect(find.byType(Wrap), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpInlineAction(
  WidgetTester tester,
  RoamlyInlineAction inlineAction, {
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: RoamlyTheme.light,
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(body: Center(child: inlineAction)),
      ),
    ),
  );
}
