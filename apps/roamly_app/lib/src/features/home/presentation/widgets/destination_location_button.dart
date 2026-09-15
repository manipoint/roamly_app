import 'package:flutter/material.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../../../localization/app_strings.dart';

final class DestinationLocationButton extends StatelessWidget {
  const DestinationLocationButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '$label, ${AppStrings.viewOnMap}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: RoamlyRadii.medium,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: RoamlySpacing.space8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: RoamlySpacing.space20,
                  color: colors.primary,
                ),
                const SizedBox(width: RoamlySpacing.space8),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: RoamlySpacing.space8),
                Text(
                  AppStrings.viewOnMap,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: RoamlySpacing.space4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: RoamlySpacing.space20,
                  color: colors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
