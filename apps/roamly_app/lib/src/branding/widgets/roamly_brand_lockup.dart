import 'package:flutter/material.dart';
import 'package:roamly_app/src/branding/widgets/roamly_app_icon.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

/// Reusable vertical Roamly brand identity.
final class RoamlyBrandLockup extends StatelessWidget {
  const RoamlyBrandLockup({
    super.key,
    required this.iconSize,
    this.showTagline = true,
  }) : assert(iconSize > 0, 'iconSize must be greater than zero');

  final double iconSize;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final headlineStyle = Theme.of(context).textTheme.headlineLarge;

    return Semantics(
      container: true,
      label: showTagline
          ? '${AppStrings.appName}. ${AppStrings.brandTagline}'
          : AppStrings.appName,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RoamlyAppIcon(size: iconSize),
          const SizedBox(height: RoamlySpacing.space8),
          ExcludeSemantics(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  const TextSpan(text: AppStrings.appNamePrefix),
                  TextSpan(
                    text: AppStrings.appNameEmphasis,
                    style: headlineStyle?.copyWith(color: colorScheme.primary),
                  ),
                ],
              ),
              key: const ValueKey<String>('roamly-brand-name'),
              textAlign: TextAlign.center,
              style: headlineStyle,
            ),
          ),
          if (showTagline) ...<Widget>[
            const SizedBox(height: RoamlySpacing.space4),
            ExcludeSemantics(
              child: Text(
                AppStrings.brandTagline,
                key: const ValueKey<String>('roamly-brand-tagline'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: 1.8,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
