import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:roamly_app/src/app/widgets/session_loading_view.dart';
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

  testWidgets('redirects a guest from root to sign in', (tester) async {
    final harness = createRouter(() async => null);
    addTearDown(harness.container.dispose);

    await pumpRouter(tester, harness);
    await tester.pumpAndSettle();

    expect(currentPath(harness.router), AppRoutePaths.signIn);
    expect(find.text('Sign in to continue.'), findsOneWidget);
  });

  testWidgets('redirects an authenticated user from root to home', (
    tester,
  ) async {
    final harness = createRouter(() async => authenticatedUser);
    addTearDown(harness.container.dispose);

    await pumpRouter(tester, harness);
    await tester.pumpAndSettle();

    expect(currentPath(harness.router), AppRoutePaths.home);
    expect(find.text(authenticatedUser.email), findsOneWidget);
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

  testWidgets('allows a guest to open the registration route', (tester) async {
    final harness = createRouter(() async => null);
    addTearDown(harness.container.dispose);

    await pumpRouter(tester, harness);
    await tester.pumpAndSettle();

    harness.router.go(AppRoutePaths.register);
    await tester.pumpAndSettle();

    expect(currentPath(harness.router), AppRoutePaths.register);
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
    expect(find.text(authenticatedUser.email), findsOneWidget);
  });
}
