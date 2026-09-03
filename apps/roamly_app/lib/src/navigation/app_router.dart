import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roamly_app/src/app/auth_gate.dart';
import 'package:roamly_app/src/app/widgets/authenticated_view.dart';
import 'package:roamly_app/src/app/widgets/unauthenticated_view.dart';
import 'package:roamly_app/src/navigation/app_routes.dart';
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

    bool isAuthenticationPath(String location) {
      return location == AppRoutePaths.signIn ||
          location == AppRoutePaths.register;
    }

    final router = GoRouter(
      initialLocation: AppRoutePaths.root,
      refreshListenable: authState,
      redirect: (context, state) {
        final authentication = authState.value;
        final currentLocation = state.matchedLocation;
        final isOnAuthenticationRoute = isAuthenticationPath(currentLocation);

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

          if (pendingUri != null && isAuthenticationPath(pendingUri.path)) {
            final destination = pendingLocation;
            pendingLocation = null;
            return destination;
          }

          if (isOnAuthenticationRoute) {
            return null;
          }

          if (currentLocation != AppRoutePaths.root) {
            pendingLocation ??= state.uri.toString();
          }

          return AppRoutePaths.signIn;
        }

        final destination = pendingLocation;
        pendingLocation = null;

        if (destination != null) {
          final destinationUri = Uri.tryParse(destination);

          if (destinationUri != null &&
              destinationUri.path != AppRoutePaths.root &&
              !isAuthenticationPath(destinationUri.path)) {
            return destination;
          }
        }

        if (currentLocation == AppRoutePaths.root || isOnAuthenticationRoute) {
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
          path: AppRoutePaths.signIn,
          name: AppRouteNames.signIn,
          builder: (context, state) {
            return UnauthenticatedView(hasFailure: authState.value.hasError);
          },
        ),
        GoRoute(
          path: AppRoutePaths.register,
          name: AppRouteNames.register,
          builder: (context, state) {
            // TODO(imranlatif): Replace with RegisterPage.
            return UnauthenticatedView(hasFailure: authState.value.hasError);
          },
        ),
        GoRoute(
          path: AppRoutePaths.home,
          name: AppRouteNames.home,
          builder: (context, state) {
            final user = authState.value.value;

            if (user == null) {
              return const AuthGate();
            }

            return AuthenticatedView(email: user.email);
          },
        ),
      ],
    );

    ref.onDispose(router.dispose);

    return router;
  }
}
