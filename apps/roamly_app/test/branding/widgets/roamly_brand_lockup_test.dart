import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/branding/roamly_assets.dart';
import 'package:roamly_app/src/branding/widgets/roamly_app_icon.dart';
import 'package:roamly_app/src/branding/widgets/roamly_brand_lockup.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  testWidgets('renders the transparent brand icon, name, and tagline', (
    tester,
  ) async {
    await _pumpLockup(tester, theme: RoamlyTheme.light);

    expect(find.byType(RoamlyAppIcon), findsOneWidget);
    expect(find.text(AppStrings.appName, findRichText: true), findsOneWidget);
    expect(find.text(AppStrings.brandTagline), findsOneWidget);

    final image = tester.widget<Image>(
      find.byKey(const ValueKey<String>('roamly-app-icon-image')),
    );
    expect((image.image as AssetImage).assetName, RoamlyAssets.appIcon);
  });

  testWidgets('uses different semantic glow colors for light and dark themes', (
    tester,
  ) async {
    await _pumpLockup(tester, theme: RoamlyTheme.light);
    final lightDecoration = _iconDecoration(tester);

    await _pumpLockup(tester, theme: RoamlyTheme.dark);
    final darkDecoration = _iconDecoration(tester);

    expect(
      (lightDecoration.gradient! as RadialGradient).colors.first,
      RoamlyTheme.light.colorScheme.primary.withValues(alpha: 0.10),
    );
    expect(
      (darkDecoration.gradient! as RadialGradient).colors.first,
      RoamlyTheme.dark.colorScheme.secondary.withValues(alpha: 0.16),
    );
  });

  testWidgets('can omit the tagline in compact contexts', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: RoamlyTheme.light,
        home: const Scaffold(
          body: RoamlyBrandLockup(iconSize: 80, showTagline: false),
        ),
      ),
    );

    expect(find.text(AppStrings.brandTagline), findsNothing);
  });
}

BoxDecoration _iconDecoration(WidgetTester tester) {
  final decoratedBox = tester.widget<DecoratedBox>(
    find.byKey(const ValueKey<String>('roamly-app-icon-backdrop')),
  );
  return decoratedBox.decoration as BoxDecoration;
}

Future<void> _pumpLockup(
  WidgetTester tester, {
  required ThemeData theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: const Scaffold(
        body: Center(child: RoamlyBrandLockup(iconSize: 120)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
