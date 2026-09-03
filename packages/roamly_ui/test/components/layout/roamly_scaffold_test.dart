import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  const bodyKey = ValueKey('body');

  Future<void> pumpScaffold(
    WidgetTester tester, {
    Widget body = const SizedBox.expand(key: bodyKey),
    PreferredSizeWidget? appBar,
    Widget? bottomNavigationBar,
    Widget? floatingActionButton,
    Color? backgroundColor,
    EdgeInsetsGeometry bodyPadding = const EdgeInsets.symmetric(
      horizontal: RoamlySpacing.space20,
    ),
    double? maxContentWidth,
    bool useSafeArea = true,
    bool? safeAreaTop,
    bool? safeAreaBottom,
    bool resizeToAvoidBottomInset = true,
    bool extendBody = false,
    bool extendBodyBehindAppBar = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: RoamlyTheme.light,
        home: RoamlyScaffold(
          body: body,
          appBar: appBar,
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
          backgroundColor: backgroundColor,
          bodyPadding: bodyPadding,
          maxContentWidth: maxContentWidth,
          useSafeArea: useSafeArea,
          safeAreaTop: safeAreaTop,
          safeAreaBottom: safeAreaBottom,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          extendBody: extendBody,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
        ),
      ),
    );
  }

  SafeArea bodySafeArea(WidgetTester tester) {
    return tester.widget<SafeArea>(
      find
          .ancestor(of: find.byKey(bodyKey), matching: find.byType(SafeArea))
          .first,
    );
  }

  testWidgets('uses Roamly background, padding, and safe-area defaults', (
    tester,
  ) async {
    await pumpScaffold(tester);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final safeArea = bodySafeArea(tester);
    final padding = tester.widget<Padding>(
      find.descendant(
        of: find.byType(RoamlyScaffold),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Padding &&
              widget.padding ==
                  const EdgeInsets.symmetric(horizontal: RoamlySpacing.space20),
        ),
      ),
    );

    expect(scaffold.backgroundColor, RoamlyTheme.light.colorScheme.surface);
    expect(safeArea.top, isTrue);
    expect(safeArea.bottom, isTrue);
    expect(safeArea.left, isTrue);
    expect(safeArea.right, isTrue);
    expect(
      padding.padding,
      const EdgeInsets.symmetric(horizontal: RoamlySpacing.space20),
    );
  });

  testWidgets('avoids duplicate insets beside app and navigation bars', (
    tester,
  ) async {
    await pumpScaffold(
      tester,
      appBar: AppBar(title: const Text('Trips')),
      bottomNavigationBar: const SizedBox(
        key: ValueKey('navigation'),
        height: 80,
      ),
    );

    final safeArea = bodySafeArea(tester);

    expect(safeArea.top, isFalse);
    expect(safeArea.bottom, isFalse);
    expect(find.text('Trips'), findsOneWidget);
    expect(find.byKey(const ValueKey('navigation')), findsOneWidget);
  });

  testWidgets('honors explicit safe-area overrides', (tester) async {
    await pumpScaffold(
      tester,
      appBar: AppBar(),
      bottomNavigationBar: const SizedBox(height: 80),
      safeAreaTop: true,
      safeAreaBottom: true,
    );

    final safeArea = bodySafeArea(tester);

    expect(safeArea.top, isTrue);
    expect(safeArea.bottom, isTrue);
  });

  testWidgets('constrains and centers content on a wide viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpScaffold(tester, maxContentWidth: 480);

    expect(tester.getSize(find.byKey(bodyKey)).width, 480);
    expect(tester.getCenter(find.byKey(bodyKey)).dx, 600);
  });

  testWidgets('supports edge-to-edge full-bleed content', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpScaffold(
      tester,
      useSafeArea: false,
      bodyPadding: EdgeInsets.zero,
    );

    expect(find.byType(SafeArea), findsNothing);
    expect(tester.getSize(find.byKey(bodyKey)), const Size(400, 800));
  });

  testWidgets('forwards scaffold behavior and action slots', (tester) async {
    const customBackground = Color(0xFF123456);

    await pumpScaffold(
      tester,
      floatingActionButton: const FloatingActionButton(
        onPressed: null,
        child: Icon(Icons.add),
      ),
      backgroundColor: customBackground,
      resizeToAvoidBottomInset: false,
      extendBody: true,
      extendBodyBehindAppBar: true,
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));

    expect(scaffold.backgroundColor, customBackground);
    expect(scaffold.resizeToAvoidBottomInset, isFalse);
    expect(scaffold.extendBody, isTrue);
    expect(scaffold.extendBodyBehindAppBar, isTrue);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  test('rejects a non-positive maximum content width', () {
    expect(
      () => RoamlyScaffold(body: const SizedBox.shrink(), maxContentWidth: 0),
      throwsAssertionError,
    );
  });
}
