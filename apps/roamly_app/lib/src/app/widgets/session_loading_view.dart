import 'package:flutter/material.dart';
import 'package:roamly_app/src/branding/roamly_assets.dart';
import 'package:roamly_ui/roamly_ui.dart';

/// Displays the branded loading state while the saved session is restored.
final class SessionLoadingView extends StatelessWidget {
  const SessionLoadingView({super.key, required this.valueKey});

  /// Stable identifier used by widget tests and accessibility tooling.
  final String valueKey;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;

    final backgroundAsset = isDarkMode
        ? RoamlyAssets.splashBackgroundDark
        : RoamlyAssets.splashBackgroundLight;

    final logoAsset = isDarkMode
        ? RoamlyAssets.logoOnDark
        : RoamlyAssets.logoOnLight;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            backgroundAsset,
            key: const ValueKey('session-loading-background'),
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(RoamlySpacing.space24),
              child: Center(
                child: Semantics(
                  container: true,
                  liveRegion: true,
                  label: 'Loading Roamly',
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          logoAsset,
                          key: const ValueKey('session-loading-logo'),
                          width: double.infinity,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                        const SizedBox(height: RoamlySpacing.space32),
                        FractionallySizedBox(
                          widthFactor: 0.55,
                          child: RoamlySkeleton(
                            key: Key(valueKey),
                            width: double.infinity,
                            height: 6,
                            borderRadius: RoamlyRadii.pill,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
