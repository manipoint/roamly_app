import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/app/roamly_app.dart';
import 'package:roamly_auth/roamly_auth.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  Future<void> pumpRoamlyApp(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWithBuild((ref, notifier) async {
            return null;
          }),
        ],
        child: const RoamlyApp(),
      ),
    );
  }

  testWidgets('configures the root app with Roamly system themes', (
    tester,
  ) async {
    await pumpRoamlyApp(tester);
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(app.title, 'Roamly AI');
    expect(app.debugShowCheckedModeBanner, isFalse);
    expect(app.theme, same(RoamlyTheme.light));
    expect(app.darkTheme, same(RoamlyTheme.dark));
    expect(app.themeMode, ThemeMode.system);
    expect(find.byKey(const ValueKey('unauthenticated-view')), findsOneWidget);
  });

  testWidgets('selects the dark Roamly theme for a dark system preference', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await pumpRoamlyApp(tester);
    await tester.pumpAndSettle();

    final context = tester.element(
      find.byKey(const ValueKey('unauthenticated-view')),
    );

    expect(Theme.of(context).brightness, Brightness.dark);
    expect(Theme.of(context).colorScheme, equals(RoamlyTheme.dark.colorScheme));
  });
}
