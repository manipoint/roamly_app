import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roamly_app/src/app/auth_gate.dart';
import 'package:roamly_app/src/features/assistant/presentation/pages/assistant_page.dart';
import 'package:roamly_app/src/features/auth/presentation/pages/register_page.dart';
import 'package:roamly_app/src/features/auth/presentation/pages/sign_in_page.dart';
import 'package:roamly_app/src/features/home/presentation/pages/home_page.dart';
import 'package:roamly_app/src/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:roamly_app/src/features/profile/presentation/pages/profile_page.dart';
import 'package:roamly_app/src/features/saved/presentation/pages/saved_page.dart';
import 'package:roamly_app/src/features/trips/presentation/pages/trips_page.dart';
import 'package:roamly_app/src/navigation/app_routes.dart';
import 'package:roamly_app/src/navigation/authenticated_app_shell.dart';
import 'package:roamly_auth/roamly_auth.dart';

/// Provides the application router through Riverpod.
final appRouterProvider = Provider<GoRouter>(AppRouter.create);

/// Creates Roamly's authentication-aware navigation graph.
abstract final class AppRouter {
  static GoRouter create(Ref ref) {
    final initialAuthState = ref.read(authControllerProvider);

    final authState = ValueNotifier<AsyncValue<AuthUser?>>(initialAuthState);

    bool hasCompletedInitialAuthCheck = !initialAuthState.isLoading;
    String? pendingLocation;

    ref.listen<AsyncValue<AuthUser?>>(authControllerProvider, (previous, next) {
      if (!next.isLoading) {
        hasCompletedInitialAuthCheck = true;
      }

      authState.value = next;
    });

    ref.onDispose(authState.dispose);

    bool isGuestPath(String location) {
      return location == AppRoutePaths.welcome ||
          location == AppRoutePaths.signIn ||
          location == AppRoutePaths.register;
    }

    final router = GoRouter(
      initialLocation: AppRoutePaths.root,
      refreshListenable: authState,
      redirect: (context, state) {
        final authentication = authState.value;
        final currentLocation = state.matchedLocation;
        final isOnGuestRoute = isGuestPath(currentLocation);

        final isRestoringSession =
            !hasCompletedInitialAuthCheck && authentication.isLoading;

        if (isRestoringSession) {
          if (currentLocation != AppRoutePaths.root) {
            pendingLocation ??= state.uri.toString();
            return AppRoutePaths.root;
          }

          return null;
        }

        final user = authentication.value;

        if (user == null) {
          final pendingUri = pendingLocation == null
              ? null
              : Uri.tryParse(pendingLocation!);

          if (pendingUri != null && isGuestPath(pendingUri.path)) {
            final destination = pendingLocation;
            pendingLocation = null;
            return destination;
          }

          if (isOnGuestRoute) {
            return null;
          }

          if (currentLocation == AppRoutePaths.root) {
            return AppRoutePaths.welcome;
          }

          pendingLocation ??= state.uri.toString();

          return AppRoutePaths.signIn;
        }

        final destination = pendingLocation;
        pendingLocation = null;

        if (destination != null) {
          final destinationUri = Uri.tryParse(destination);

          if (destinationUri != null &&
              destinationUri.path != AppRoutePaths.root &&
              !isGuestPath(destinationUri.path)) {
            return destination;
          }
        }

        if (currentLocation == AppRoutePaths.root || isOnGuestRoute) {
          return AppRoutePaths.home;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppRoutePaths.root,
          name: AppRouteNames.root,
          builder: (context, state) {
            return const AuthGate();
          },
        ),
        GoRoute(
          path: AppRoutePaths.welcome,
          name: AppRouteNames.welcome,
          builder: (context, state) {
            return const WelcomePage();
          },
        ),
        GoRoute(
          path: AppRoutePaths.signIn,
          name: AppRouteNames.signIn,
          builder: (context, state) {
            return const SignInPage();
          },
        ),
        GoRoute(
          path: AppRoutePaths.register,
          name: AppRouteNames.register,
          builder: (context, state) {
            return const RegisterPage();
          },
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AuthenticatedAppShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutePaths.home,
                  name: AppRouteNames.home,
                  builder: (context, state) {
                    return const HomePage();
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutePaths.trips,
                  name: AppRouteNames.trips,
                  builder: (context, state) {
                    return const TripsPage();
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutePaths.assistant,
                  name: AppRouteNames.assistant,
                  builder: (context, state) {
                    return const AssistantPage();
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutePaths.saved,
                  name: AppRouteNames.saved,
                  builder: (context, state) {
                    return const SavedPage();
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutePaths.profile,
                  name: AppRouteNames.profile,
                  builder: (context, state) {
                    return const ProfilePage();
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );

    ref.onDispose(router.dispose);

    return router;
  }
}
