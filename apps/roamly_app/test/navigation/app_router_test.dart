import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:roamly_app/src/app/widgets/session_loading_view.dart';
import 'package:roamly_app/src/features/auth/presentation/pages/register_page.dart';
import 'package:roamly_app/src/features/auth/presentation/pages/sign_in_page.dart';
import 'package:roamly_app/src/features/home/presentation/pages/home_page.dart';
import 'package:roamly_app/src/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:roamly_app/src/navigation/app_router.dart';
import 'package:roamly_app/src/navigation/app_routes.dart';
import 'package:roamly_auth/roamly_auth.dart';

void main() {
  final authenticatedUser = AuthUser(
    id: 'user-1',
    email: 'traveler@roamly.test',
    status: AuthUserStatus.active,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  ({ProviderContainer container, GoRouter router}) createRouter(
    Future<AuthUser?> Function() restoreSession,
  ) {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWithBuild((ref, notifier) {
          return restoreSession();
        }),
      ],
    );

    return (container: container, router: container.read(appRouterProvider));
  }

  Future<void> pumpRouter(
    WidgetTester tester,
    ({ProviderContainer container, GoRouter router}) harness,
  ) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: harness.container,
        child: MaterialApp.router(routerConfig: harness.router),
      ),
    );
  }

  String currentPath(GoRouter router) {
    return router.routeInformationProvider.value.uri.path;
  }

  testWidgets('keeps the root loading route while restoring a session', (
    tester,
  ) async {
    final pendingSession = Completer<AuthUser?>();
    final harness = createRouter(() => pendingSession.future);
    addTearDown(harness.container.dispose);

    await pumpRouter(tester, harness);
    await tester.pump();

    expect(currentPath(harness.router), AppRoutePaths.root);
    expect(find.byType(SessionLoadingView), findsOneWidget);
  });

  testWidgets('redirects a guest from root to welcome', (tester) async {
    final harness = createRouter(() async => null);
    addTearDown(harness.container.dispose);

    await pumpRouter(tester, harness);
    await tester.pumpAndSettle();

    expect(currentPath(harness.router), AppRoutePaths.welcome);
    expect(find.byType(WelcomePage), findsOneWidget);
  });

  testWidgets('redirects an authenticated user from root to home', (
    tester,
  ) async {
    final harness = createRouter(() async => authenticatedUser);
    addTearDown(harness.container.dispose);

    await pumpRouter(tester, harness);
    await tester.pumpAndSettle();

    expect(currentPath(harness.router), AppRoutePaths.home);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('prevents an authenticated user from opening auth routes', (
    tester,
  ) async {
    final harness = createRouter(() async => authenticatedUser);
    addTearDown(harness.container.dispose);

    await pumpRouter(tester, harness);
    await tester.pumpAndSettle();

    harness.router.go(AppRoutePaths.signIn);
    await tester.pumpAndSettle();

    expect(currentPath(harness.router), AppRoutePaths.home);
  });

  testWidgets('prevents an authenticated user from opening welcome', (
    tester,
  ) async {
    final harness = createRouter(() async => authenticatedUser);
    addTearDown(harness.container.dispose);

    await pumpRouter(tester, harness);
    await tester.pumpAndSettle();

    harness.router.go(AppRoutePaths.welcome);
    await tester.pumpAndSettle();

    expect(currentPath(harness.router), AppRoutePaths.home);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('sends a guest opening a protected route to sign in', (
    tester,
  ) async {
    final harness = createRouter(() async => null);
    addTearDown(harness.container.dispose);

    await pumpRouter(tester, harness);
    await tester.pumpAndSettle();

    harness.router.go(AppRoutePaths.trips);
    await tester.pumpAndSettle();

    expect(currentPath(harness.router), AppRoutePaths.signIn);
    expect(find.byType(SignInPage), findsOneWidget);
  });

  testWidgets('allows a guest to open the registration route', (tester) async {
    final harness = createRouter(() async => null);
    addTearDown(harness.container.dispose);

    await pumpRouter(tester, harness);
    await tester.pumpAndSettle();

    harness.router.go(AppRoutePaths.register);
    await tester.pumpAndSettle();

    expect(currentPath(harness.router), AppRoutePaths.register);
    expect(find.byType(RegisterPage), findsOneWidget);
  });

  testWidgets('restores a protected destination after authentication', (
    tester,
  ) async {
    final pendingSession = Completer<AuthUser?>();
    final harness = createRouter(() => pendingSession.future);
    addTearDown(harness.container.dispose);

    await pumpRouter(tester, harness);
    await tester.pump();

    harness.router.go(AppRoutePaths.home);
    await tester.pump();

    expect(currentPath(harness.router), AppRoutePaths.root);

    pendingSession.complete(authenticatedUser);
    await tester.pumpAndSettle();

    expect(currentPath(harness.router), AppRoutePaths.home);
    expect(find.byType(HomePage), findsOneWidget);
  });
}
