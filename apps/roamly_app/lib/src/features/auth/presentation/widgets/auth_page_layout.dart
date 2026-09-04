import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:roamly_app/src/branding/roamly_assets.dart';
import 'package:roamly_app/src/features/auth/presentation/layout/auth_layout_metrics.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

final class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final backgroundAsset = brightness == Brightness.dark
        ? RoamlyAssets.splashBackgroundDark
        : RoamlyAssets.splashBackgroundLight;
    final logoAsset = RoamlyAssets.appIcon;

    return RoamlyScaffold(
      bodyPadding: EdgeInsets.zero, // ← full control khud lo
      useSafeArea: false, // ← Scaffold khud SafeArea na lagaye
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              backgroundAsset,
              key: const ValueKey<String>('auth-background'),
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const verticalPadding = RoamlySpacing.space32;
                final minimumHeight = math.max(
                  0.0,
                  constraints.maxHeight - (verticalPadding * 2),
                );
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: RoamlySpacing.space24,
                    vertical: verticalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minimumHeight),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AuthLayoutMetrics.maxContentWidth,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Image.asset(
                                logoAsset,
                                width: AuthLayoutMetrics.logoWidth,
                                fit: BoxFit.contain,
                                semanticLabel: AppStrings.appName,
                              ),
                            ),
                            const SizedBox(height: RoamlySpacing.space8),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: RoamlySpacing.space8),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: RoamlySpacing.space48),
                            child,
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
