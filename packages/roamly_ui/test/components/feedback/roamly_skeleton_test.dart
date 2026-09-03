import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  const skeletonKey = ValueKey('skeleton');

  Future<void> pumpSkeleton(
    WidgetTester tester, {
    ThemeData? theme,
    double width = 180,
    double height = 24,
    BorderRadiusGeometry? borderRadius,
    BoxShape shape = BoxShape.rectangle,
    bool animate = true,
    bool disableAnimations = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: theme ?? RoamlyTheme.light,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Center(
            child: RoamlySkeleton(
              key: skeletonKey,
              width: width,
              height: height,
              borderRadius: borderRadius,
              shape: shape,
              animate: animate,
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration decorationOf(WidgetTester tester) {
    final decoratedBox = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(skeletonKey),
        matching: find.byType(DecoratedBox),
      ),
    );

    return decoratedBox.decoration as BoxDecoration;
  }

  testWidgets('uses the requested size and repaint boundary', (tester) async {
    await pumpSkeleton(tester, width: 240, height: 48);

    expect(tester.getSize(find.byKey(skeletonKey)), const Size(240, 48));
    expect(
      find.descendant(
        of: find.byKey(skeletonKey),
        matching: find.byType(RepaintBoundary),
      ),
      findsOneWidget,
    );
  });

  testWidgets('applies radius only to rectangular placeholders', (
    tester,
  ) async {
    const radius = BorderRadius.all(Radius.circular(16));

    await pumpSkeleton(tester, borderRadius: radius, animate: false);

    expect(decorationOf(tester).shape, BoxShape.rectangle);
    expect(decorationOf(tester).borderRadius, radius);

    await pumpSkeleton(
      tester,
      width: 48,
      height: 48,
      shape: BoxShape.circle,
      animate: false,
    );

    expect(decorationOf(tester).shape, BoxShape.circle);
    expect(decorationOf(tester).borderRadius, isNull);
  });

  testWidgets('renders a theme-derived static color when animation is off', (
    tester,
  ) async {
    await pumpSkeleton(tester, animate: false);

    final colors = RoamlyTheme.light.colorScheme;
    final expectedColor = Color.alphaBlend(
      colors.onSurface.withValues(alpha: 0.08),
      colors.surface,
    );
    final decoration = decorationOf(tester);

    expect(decoration.color, expectedColor);
    expect(decoration.gradient, isNull);
  });

  testWidgets('uses the dark theme colors', (tester) async {
    await pumpSkeleton(tester, theme: RoamlyTheme.dark, animate: false);

    final colors = RoamlyTheme.dark.colorScheme;
    final expectedColor = Color.alphaBlend(
      colors.onSurface.withValues(alpha: 0.08),
      colors.surface,
    );

    expect(decorationOf(tester).color, expectedColor);
  });

  testWidgets('animates a 16 percent highlight across the placeholder', (
    tester,
  ) async {
    await pumpSkeleton(tester);

    final initialGradient = decorationOf(tester).gradient! as LinearGradient;
    final colors = RoamlyTheme.light.colorScheme;
    final expectedHighlight = Color.alphaBlend(
      colors.onSurface.withValues(alpha: 0.16),
      colors.surface,
    );

    expect(initialGradient.colors[1], expectedHighlight);

    await tester.pump(const Duration(milliseconds: 300));

    final movedGradient = decorationOf(tester).gradient! as LinearGradient;
    expect(movedGradient.begin, isNot(initialGradient.begin));
  });

  testWidgets('disables shimmer when reduced motion is requested', (
    tester,
  ) async {
    await pumpSkeleton(tester, disableAnimations: true);

    final initialDecoration = decorationOf(tester);
    expect(initialDecoration.gradient, isNull);
    expect(initialDecoration.color, isNotNull);

    await tester.pump(const Duration(seconds: 2));

    expect(decorationOf(tester), initialDecoration);
  });

  testWidgets('stops animation when animate changes to false', (tester) async {
    await pumpSkeleton(tester);
    expect(decorationOf(tester).gradient, isNotNull);

    await pumpSkeleton(tester, animate: false);

    expect(decorationOf(tester).gradient, isNull);
    expect(decorationOf(tester).color, isNotNull);
  });

  testWidgets('disposes its animation controller without ticker errors', (
    tester,
  ) async {
    await pumpSkeleton(tester);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox.shrink());

    expect(tester.takeException(), isNull);
  });
}
