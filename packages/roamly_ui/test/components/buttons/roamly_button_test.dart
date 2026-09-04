import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  group('RoamlyButton', () {
    testWidgets('builds the Material button matching each variant', (
      tester,
    ) async {
      await _pumpButton(tester, const RoamlyButton.primary(label: 'Primary'));
      expect(find.byType(FilledButton), findsOneWidget);

      await _pumpButton(
        tester,
        const RoamlyButton.secondary(label: 'Secondary'),
      );
      expect(find.byType(OutlinedButton), findsOneWidget);

      await _pumpButton(tester, const RoamlyButton.ghost(label: 'Ghost'));
      expect(find.byType(TextButton), findsOneWidget);

      await _pumpButton(
        tester,
        const RoamlyButton.destructive(label: 'Destructive'),
      );
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('invokes the supplied callback', (tester) async {
      var tapCount = 0;
      await _pumpButton(
        tester,
        RoamlyButton.primary(label: 'Continue', onPressed: () => tapCount++),
      );

      await tester.tap(find.byType(RoamlyButton));

      expect(tapCount, 1);
    });

    testWidgets('disables interaction and displays progress while loading', (
      tester,
    ) async {
      var tapped = false;
      await _pumpButton(
        tester,
        RoamlyButton.primary(
          label: 'Continue',
          isLoading: true,
          onPressed: () => tapped = true,
        ),
      );

      final materialButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(materialButton.onPressed, isNull);
      expect(find.byKey(const ValueKey('loading')), findsOneWidget);

      await tester.tap(find.byType(RoamlyButton));
      expect(tapped, isFalse);
    });

    testWidgets('keeps the primary loading state visually prominent', (
      tester,
    ) async {
      await _pumpButton(
        tester,
        const RoamlyButton.primary(label: 'Continue', isLoading: true),
      );

      final context = tester.element(find.byType(RoamlyButton));
      final colors = Theme.of(context).colorScheme;
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );

      expect(
        button.style?.backgroundColor?.resolve({WidgetState.disabled}),
        colors.primary,
      );
      expect(
        button.style?.foregroundColor?.resolve({WidgetState.disabled}),
        colors.onPrimary,
      );
      expect(indicator.color, colors.onPrimary);
    });

    testWidgets('uses the primary color for secondary loading progress', (
      tester,
    ) async {
      await _pumpButton(
        tester,
        const RoamlyButton.secondary(label: 'Continue', isLoading: true),
      );

      final context = tester.element(find.byType(RoamlyButton));
      final colors = Theme.of(context).colorScheme;
      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );

      expect(
        button.style?.foregroundColor?.resolve({WidgetState.disabled}),
        colors.primary,
      );
      expect(
        button.style?.side?.resolve({WidgetState.disabled})?.color,
        colors.primary,
      );
      expect(indicator.color, colors.primary);
    });

    testWidgets('uses the primary color for ghost loading progress', (
      tester,
    ) async {
      await _pumpButton(
        tester,
        const RoamlyButton.ghost(label: 'Continue', isLoading: true),
      );

      final context = tester.element(find.byType(RoamlyButton));
      final colors = Theme.of(context).colorScheme;
      final button = tester.widget<TextButton>(find.byType(TextButton));
      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );

      expect(
        button.style?.foregroundColor?.resolve({WidgetState.disabled}),
        colors.primary,
      );
      expect(indicator.color, colors.primary);
    });

    testWidgets('uses the error color for destructive actions', (tester) async {
      await _pumpButton(
        tester,
        const RoamlyButton.destructive(label: 'Sign out'),
      );

      final context = tester.element(find.byType(RoamlyButton));
      final colors = Theme.of(context).colorScheme;
      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));

      expect(
        button.style?.foregroundColor?.resolve(<WidgetState>{}),
        colors.error,
      );
      expect(button.style?.side?.resolve(<WidgetState>{})?.color, colors.error);
    });

    testWidgets('renders an optional leading icon', (tester) async {
      await _pumpButton(
        tester,
        const RoamlyButton.secondary(
          label: 'Explore',
          leadingIcon: Icon(Icons.public),
        ),
      );

      expect(find.byIcon(Icons.public), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
    });

    testWidgets('expands to the width supplied by its parent', (tester) async {
      await _pumpButton(
        tester,
        const RoamlyButton.primary(label: 'Continue', expand: true),
        width: 240,
      );

      expect(tester.getSize(find.byType(RoamlyButton)).width, 240);
    });

    testWidgets('supports compact screens and large accessibility text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpButton(
        tester,
        const RoamlyButton.primary(
          label: 'Continue planning my trip',
          leadingIcon: Icon(Icons.arrow_forward),
          expand: true,
        ),
        width: 288,
        textScaler: const TextScaler.linear(2),
      );

      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });
}

Future<void> _pumpButton(
  WidgetTester tester,
  RoamlyButton button, {
  double width = 300,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: RoamlyTheme.light,
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: Center(
            child: SizedBox(width: width, child: button),
          ),
        ),
      ),
    ),
  );
}
