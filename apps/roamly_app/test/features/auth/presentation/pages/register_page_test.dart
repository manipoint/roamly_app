import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:roamly_app/src/branding/roamly_assets.dart';
import 'package:roamly_app/src/features/auth/presentation/pages/register_page.dart';
import 'package:roamly_app/src/features/auth/presentation/widgets/register_form.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_app/src/navigation/app_routes.dart';
import 'package:roamly_auth/roamly_auth.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  testWidgets('renders registration content with light branding', (
    tester,
  ) async {
    await _pumpPage(tester, restoreSession: () async => null);
    await tester.pumpAndSettle();

    expect(find.byType(RegisterPage), findsOneWidget);
    expect(find.byType(RegisterForm), findsOneWidget);
    expect(find.text(AppStrings.createYourAccount), findsOneWidget);
    expect(find.text(AppStrings.registerSubtitle), findsOneWidget);

    final logo = tester.widget<Image>(find.byType(Image));
    expect((logo.image as AssetImage).assetName, RoamlyAssets.logoOnLight);
  });

  testWidgets('uses dark branding with the dark theme', (tester) async {
    await _pumpPage(
      tester,
      restoreSession: () async => null,
      theme: RoamlyTheme.dark,
    );
    await tester.pumpAndSettle();

    final logo = tester.widget<Image>(find.byType(Image));
    expect((logo.image as AssetImage).assetName, RoamlyAssets.logoOnDark);
  });

  testWidgets('disables the registration form while auth is loading', (
    tester,
  ) async {
    final pendingSession = Completer<AuthUser?>();
    addTearDown(() {
      if (!pendingSession.isCompleted) {
        pendingSession.complete(null);
      }
    });

    await _pumpPage(tester, restoreSession: () => pendingSession.future);
    await tester.pump();

    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
    expect(fields, hasLength(3));
    expect(fields.every((field) => field.enabled == false), isTrue);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('remains scrollable without overflow on a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpPage(tester, restoreSession: () async => null);
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens sign in from the existing-account action', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutePaths.register,
      routes: [
        GoRoute(
          path: AppRoutePaths.register,
          name: AppRouteNames.register,
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: AppRoutePaths.signIn,
          name: AppRouteNames.signIn,
          builder: (context, state) => const Text('Sign-in destination'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWithBuild((ref, notifier) async {
            return null;
          }),
        ],
        child: MaterialApp.router(
          theme: RoamlyTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final signInAction = find.text(AppStrings.signIn);
    await tester.ensureVisible(signInAction);
    await tester.pumpAndSettle();
    await tester.tap(signInAction);
    await tester.pumpAndSettle();

    expect(find.text('Sign-in destination'), findsOneWidget);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required Future<AuthUser?> Function() restoreSession,
  ThemeData? theme,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWithBuild((ref, notifier) {
          return restoreSession();
        }),
      ],
      child: MaterialApp(
        theme: theme ?? RoamlyTheme.light,
        home: const RegisterPage(),
      ),
    ),
  );
}
