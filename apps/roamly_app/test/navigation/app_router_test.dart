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
import 'package:roamly_app/src/features/preferences/domain/entities/canonical_location.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/user_preferences.dart';
import 'package:roamly_app/src/features/preferences/domain/repositories/preference_repository.dart';
import 'package:roamly_app/src/features/preferences/presentation/providers/preference_dependency_providers.dart';
import 'package:roamly_app/src/features/preferences/presentation/widgets/travel_style_step.dart';
import 'package:roamly_app/src/navigation/app_router.dart';
import 'package:roamly_app/src/navigation/app_routes.dart';
import 'package:roamly_auth/roamly_auth.dart';
import 'package:roamly_core/roamly_core.dart';

final class _PreferenceRepository implements PreferenceRepository {
  _PreferenceRepository({required this.onboardingCompleted});

  final bool onboardingCompleted;

  @override
  Future<Result<UserPreferences>> getPreferences() async {
    return Success<UserPreferences>(
      UserPreferences(
        travelStyle: null,
        interests: const <TravelInterest>{},
        budgetTier: null,
        tripPace: null,
        recommendationScope: RecommendationScope.both,
        homeLocation: null,
        onboardingCompleted: onboardingCompleted,
        personalizationReady: false,
        onboardingCompletedAt: null,
        createdAt: null,
        updatedAt: null,
      ),
    );
  }

  @override
  Future<Result<UserPreferences>> savePreferences({
    required TravelStyle travelStyle,
    required Set<TravelInterest> interests,
    required BudgetTier budgetTier,
    required TripPace tripPace,
    required RecommendationScope recommendationScope,
    required CanonicalLocation? homeLocation,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<UserPreferences>> skipOnboarding() {
    throw UnimplementedError();
  }
}

void main() {
  final authenticatedUser = AuthUser(
    id: 'user-1',
    email: 'traveler@roamly.test',
    status: AuthUserStatus.active,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  ({ProviderContainer container, GoRouter router}) createRouter(
    Future<AuthUser?> Function() restoreSession, {
    bool onboardingCompleted = true,
  }) {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWithBuild((ref, notifier) {
          return restoreSession();
        }),
        preferenceRepositoryProvider.overrideWithValue(
          _PreferenceRepository(onboardingCompleted: onboardingCompleted),
        ),
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

  testWidgets('gates authenticated content until onboarding is complete', (
    tester,
  ) async {
    final harness = createRouter(
      () async => authenticatedUser,
      onboardingCompleted: false,
    );
    addTearDown(harness.container.dispose);

    await pumpRouter(tester, harness);
    await tester.pumpAndSettle();

    expect(currentPath(harness.router), AppRoutePaths.home);
    expect(find.byType(TravelStyleStep), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
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
