import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:roamly_app/src/branding/roamly_assets.dart';
import 'package:roamly_app/src/branding/widgets/roamly_brand_lockup.dart';
import 'package:roamly_app/src/features/onboarding/presentation/layout/onboarding_layout_metrics.dart';
import 'package:roamly_app/src/features/onboarding/presentation/widgets/welcome_headline.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_app/src/navigation/app_routes.dart';
import 'package:roamly_ui/roamly_ui.dart';

final class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void _openRegistration(BuildContext context) {
    context.goNamed(AppRouteNames.register);
  }

  void _openSignIn(BuildContext context) {
    context.goNamed(AppRouteNames.signIn);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundAsset = isDarkMode
        ? RoamlyAssets.welcomeBackgroundDark
        : RoamlyAssets.welcomeBackgroundLight;
    return RoamlyScaffold(
      bodyPadding: EdgeInsets.zero,
      useSafeArea: false,
      body: Stack(
        key: const ValueKey<String>('welcome-page'),
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            backgroundAsset,
            key: const ValueKey<String>('welcome-background'),
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
          DecoratedBox(
            key: const ValueKey<String>('welcome-background-scrim'),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  theme.colorScheme.surface,
                  theme.colorScheme.surface,
                  theme.colorScheme.surface.withValues(alpha: 0.94),
                  theme.colorScheme.surface.withValues(alpha: 0),
                ],
                stops: const <double>[0, 0.45, 0.56, 0.68],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                RoamlySpacing.space24,
                0,
                RoamlySpacing.space24,
                RoamlySpacing.space4,
              ),
              child: Column(
                children: <Widget>[
                  Align(
                    alignment: Alignment.topRight,
                    child: RoamlyButton.ghost(
                      key: const ValueKey<String>('welcome-skip'),
                      onPressed: () => _openSignIn(context),
                      label: AppStrings.skip,
                    ),
                  ),
                  const Expanded(child: _WelcomeScrollableContent()),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: OnboardingLayoutMetrics.maxContentWidth,
                    ),
                    child: _WelcomeActions(
                      onGetStarted: () => _openRegistration(context),
                      onSignIn: () => _openSignIn(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _WelcomeScrollableContent extends StatelessWidget {
  const _WelcomeScrollableContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: RoamlySpacing.space8,
        bottom: RoamlySpacing.space16,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          key: const ValueKey<String>('welcome-content'),
          constraints: const BoxConstraints(
            maxWidth: OnboardingLayoutMetrics.maxContentWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const RoamlyBrandLockup(
                key: ValueKey<String>('welcome-brand-lockup'),
                iconSize: OnboardingLayoutMetrics.brandIconSize,
              ),
              const SizedBox(height: RoamlySpacing.space24),
              const WelcomeHeadline(),
              const SizedBox(height: RoamlySpacing.space16),
              Text(
                AppStrings.welcomeDescription,
                key: const ValueKey<String>('welcome-description'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _WelcomeActions extends StatelessWidget {
  const _WelcomeActions({required this.onGetStarted, required this.onSignIn});

  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('welcome-actions'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RoamlyButton.primary(
          key: const ValueKey<String>('welcome-get-started'),
          label: AppStrings.getStarted,
          expand: true,
          onPressed: onGetStarted,
        ),
        RoamlyInlineAction(
          prompt: AppStrings.haveAccount,
          actionLabel: AppStrings.signIn,
          actionKey: const ValueKey<String>('welcome-sign-in'),
          onPressed: onSignIn,
        ),
      ],
    );
  }
}
