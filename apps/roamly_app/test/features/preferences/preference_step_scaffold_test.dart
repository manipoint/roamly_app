import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/presentation/widgets/preference_step_scaffold.dart';

void main() {
  Future<void> pumpStep(
    WidgetTester tester, {
    VoidCallback? onBack,
    VoidCallback? onSkip,
    VoidCallback? onContinue,
    bool isContinueEnabled = true,
    bool isSubmitting = false,
    double textScale = 1,
    Widget body = const Text('step-content'),
  }) {
    return tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          );
        },
        home: PreferenceStepScaffold(
          currentStep: 1,
          stepCount: 3,
          title: const Text('Choose your preferences'),
          description: 'Tell us what makes a great journey for you.',
          body: body,
          onBack: onBack,
          onSkip: onSkip,
          onContinue: onContinue ?? () {},
          isContinueEnabled: isContinueEnabled,
          isSubmitting: isSubmitting,
        ),
      ),
    );
  }

  testWidgets('exposes progress and invokes navigation callbacks', (
    tester,
  ) async {
    var backCalls = 0;
    var skipCalls = 0;
    var continueCalls = 0;
    await pumpStep(
      tester,
      onBack: () => backCalls++,
      onSkip: () => skipCalls++,
      onContinue: () => continueCalls++,
    );

    expect(find.bySemanticsLabel('Step 2 of 3'), findsOneWidget);
    expect(find.text('step-content'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('preference-back')));
    await tester.tap(find.byKey(const ValueKey<String>('preference-skip')));
    await tester.tap(find.byKey(const ValueKey<String>('preference-continue')));
    expect((backCalls, skipCalls, continueCalls), (1, 1, 1));
  });

  testWidgets('omits optional navigation actions', (tester) async {
    await pumpStep(tester);
    expect(find.byKey(const ValueKey<String>('preference-back')), findsNothing);
    expect(find.byKey(const ValueKey<String>('preference-skip')), findsNothing);
  });

  testWidgets('disabled and submitting states prevent continuation', (
    tester,
  ) async {
    var calls = 0;
    await pumpStep(tester, onContinue: () => calls++, isContinueEnabled: false);
    await tester.tap(
      find.byKey(const ValueKey<String>('preference-continue')),
      warnIfMissed: false,
    );
    expect(calls, 0);

    await pumpStep(tester, onContinue: () => calls++, isSubmitting: true);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('preference-continue')),
      warnIfMissed: false,
    );
    expect(calls, 0);
  });

  testWidgets('long body scrolls without overflowing a short phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpStep(
      tester,
      body: const SizedBox(height: 700, child: Text('long-content')),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('large accessibility text does not overflow a short phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpStep(tester, textScale: 2);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
