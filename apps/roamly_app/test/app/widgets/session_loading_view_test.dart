import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/app/widgets/session_loading_view.dart';
import 'package:roamly_app/src/branding/roamly_assets.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  const loadingKey = 'auth-session-loading';

  Future<void> pumpLoadingView(
    WidgetTester tester, {
    required ThemeData theme,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const SessionLoadingView(valueKey: loadingKey),
      ),
    );
  }

  String assetNameFor(WidgetTester tester, ValueKey<String> key) {
    final image = tester.widget<Image>(find.byKey(key));
    return (image.image as AssetImage).assetName;
  }

  testWidgets('uses light branding with the light theme', (tester) async {
    await pumpLoadingView(tester, theme: RoamlyTheme.light);

    expect(
      assetNameFor(tester, const ValueKey('session-loading-background')),
      RoamlyAssets.splashBackgroundLight,
    );
    expect(
      assetNameFor(tester, const ValueKey('session-loading-logo')),
      RoamlyAssets.logoOnLight,
    );
  });

  testWidgets('uses dark branding with the dark theme', (tester) async {
    await pumpLoadingView(tester, theme: RoamlyTheme.dark);

    expect(
      assetNameFor(tester, const ValueKey('session-loading-background')),
      RoamlyAssets.splashBackgroundDark,
    );
    expect(
      assetNameFor(tester, const ValueKey('session-loading-logo')),
      RoamlyAssets.logoOnDark,
    );
  });

  testWidgets('exposes one live loading announcement and the stable key', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await pumpLoadingView(tester, theme: RoamlyTheme.light);

    expect(find.bySemanticsLabel('Loading Roamly'), findsOneWidget);
    expect(find.byKey(const Key(loadingKey)), findsOneWidget);
    expect(find.byType(RoamlySkeleton), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('does not overflow on a compact landscape viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(480, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpLoadingView(tester, theme: RoamlyTheme.light);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
