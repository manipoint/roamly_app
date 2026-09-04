import 'package:flutter/material.dart';
import 'package:roamly_app/src/branding/roamly_assets.dart';

/// Renders the transparent Roamly icon with theme-aware contrast treatment.
///
/// The multicolor artwork is never tinted. A subtle adaptive backdrop and
/// shadow preserve its contrast on both light and dark surfaces.
final class RoamlyAppIcon extends StatelessWidget {
  const RoamlyAppIcon({super.key, required this.size, this.semanticLabel})
    : assert(size > 0, 'size must be greater than zero');

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final glowColor = isDarkMode ? colorScheme.secondary : colorScheme.primary;

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        key: const ValueKey<String>('roamly-app-icon-backdrop'),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              glowColor.withValues(alpha: isDarkMode ? 0.16 : 0.10),
              glowColor.withValues(alpha: 0),
            ],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: glowColor.withValues(alpha: isDarkMode ? 0.18 : 0.12),
              blurRadius: size * 0.16,
              spreadRadius: size * 0.01,
            ),
          ],
        ),
        child: Image.asset(
          RoamlyAssets.appIcon,
          key: const ValueKey<String>('roamly-app-icon-image'),
          fit: BoxFit.contain,
          semanticLabel: semanticLabel,
          excludeFromSemantics: semanticLabel == null,
        ),
      ),
    );
  }
}
