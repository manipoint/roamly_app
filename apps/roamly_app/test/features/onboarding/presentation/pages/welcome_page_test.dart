import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:roamly_app/src/branding/roamly_assets.dart';
import 'package:roamly_app/src/branding/widgets/roamly_brand_lockup.dart';
import 'package:roamly_app/src/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:roamly_app/src/features/onboarding/presentation/widgets/welcome_headline.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_app/src/navigation/app_routes.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  testWidgets('renders welcome content with light branding', (tester) async {
    await _pumpWelcomePage(tester);

    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.text(AppStrings.getStarted), findsOneWidget);
    expect(find.text(AppStrings.haveAccount), findsOneWidget);

    final background = tester.widget<Image>(
      find.byKey(const ValueKey<String>('welcome-background')),
    );
    final icon = tester.widget<Image>(
      find.byKey(const ValueKey<String>('roamly-app-icon-image')),
    );

    expect(
      (background.image as AssetImage).assetName,
      RoamlyAssets.welcomeBackgroundLight,
    );
    expect((icon.image as AssetImage).assetName, RoamlyAssets.appIcon);
    expect(find.byType(RoamlyBrandLockup), findsOneWidget);
    expect(find.byType(WelcomeHeadline), findsOneWidget);
    expect(find.text(AppStrings.brandTagline), findsOneWidget);
  });

  testWidgets('uses dark branding with the dark theme', (tester) async {
    await _pumpWelcomePage(tester, theme: RoamlyTheme.dark);

    final background = tester.widget<Image>(
      find.byKey(const ValueKey<String>('welcome-background')),
    );
    final icon = tester.widget<Image>(
      find.byKey(const ValueKey<String>('roamly-app-icon-image')),
    );

    expect(
      (background.image as AssetImage).assetName,
      RoamlyAssets.welcomeBackgroundDark,
    );
    expect((icon.image as AssetImage).assetName, RoamlyAssets.appIcon);
  });

  testWidgets('opens registration from Get Started', (tester) async {
    final router = _createRouter();
    addTearDown(router.dispose);

    await _pumpRouter(tester, router);
    final getStarted = find.byKey(
      const ValueKey<String>('welcome-get-started'),
    );
    await tester.ensureVisible(getStarted);
    await tester.pumpAndSettle();
    await tester.tap(getStarted);
    await tester.pumpAndSettle();

    expect(find.text('Registration destination'), findsOneWidget);
  });

  testWidgets('opens sign in from the existing-account action', (tester) async {
    final router = _createRouter();
    addTearDown(router.dispose);

    await _pumpRouter(tester, router);
    final signIn = find.byKey(const ValueKey<String>('welcome-sign-in'));
    await tester.ensureVisible(signIn);
    await tester.pumpAndSettle();
    await tester.tap(signIn);
    await tester.pumpAndSettle();

    expect(find.text('Sign-in destination'), findsOneWidget);
  });

  testWidgets('Skip opens sign in because guest mode is unavailable', (
    tester,
  ) async {
    final router = _createRouter();
    addTearDown(router.dispose);

    await _pumpRouter(tester, router);
    await tester.tap(find.byKey(const ValueKey<String>('welcome-skip')));
    await tester.pumpAndSettle();

    expect(find.text('Sign-in destination'), findsOneWidget);
  });

  testWidgets('remains scrollable without overflow on a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpWelcomePage(tester);

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pins Skip at the top and actions at the bottom', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpWelcomePage(tester, textScaler: TextScaler.noScaling);

    final skipTop = tester.getTopLeft(
      find.byKey(const ValueKey<String>('welcome-skip')),
    );
    final contentTop = tester.getTopLeft(
      find.byKey(const ValueKey<String>('welcome-content')),
    );
    final actionsBottom = tester.getBottomRight(
      find.byKey(const ValueKey<String>('welcome-actions')),
    );
    final descriptionBottom = tester.getBottomRight(
      find.byKey(const ValueKey<String>('welcome-description')),
    );

    expect(skipTop.dy, lessThan(contentTop.dy));
    expect(descriptionBottom.dy, lessThan(844 * 0.6));
    expect(actionsBottom.dy, greaterThan(800));
    expect(tester.takeException(), isNull);
  });
}

GoRouter _createRouter() {
  return GoRouter(
    initialLocation: AppRoutePaths.welcome,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutePaths.welcome,
        name: AppRouteNames.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutePaths.register,
        name: AppRouteNames.register,
        builder: (context, state) => const Text('Registration destination'),
      ),
      GoRoute(
        path: AppRoutePaths.signIn,
        name: AppRouteNames.signIn,
        builder: (context, state) => const Text('Sign-in destination'),
      ),
    ],
  );
}

Future<void> _pumpWelcomePage(
  WidgetTester tester, {
  ThemeData? theme,
  TextScaler? textScaler,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? RoamlyTheme.light,
      builder: textScaler == null
          ? null
          : (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: child!,
            ),
      home: const WelcomePage(),
    ),
  );
}

Future<void> _pumpRouter(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    MaterialApp.router(theme: RoamlyTheme.light, routerConfig: router),
  );
  await tester.pumpAndSettle();
}
