import 'package:flutter/material.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../domain/entities/preference_types.dart';

/// Single-choice trip-density cards used by preference onboarding.
final class TripPaceSelector extends StatelessWidget {
  const TripPaceSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final TripPace? selected;
  final ValueChanged<TripPace> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: TripPace.values
            .map((pace) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: pace == TripPace.values.last
                        ? 0
                        : RoamlySpacing.space8,
                  ),
                  child: _TripPaceOption(
                    key: ValueKey<String>('pace-${pace.name}'),
                    icon: _iconFor(pace),
                    label: _labelFor(pace),
                    description: _descriptionFor(pace),
                    selected: selected == pace,
                    onTap: () => onSelected(pace),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  static IconData _iconFor(TripPace pace) {
    return switch (pace) {
      TripPace.relaxed => Icons.access_time_rounded,
      TripPace.balanced => Icons.explore_outlined,
      TripPace.packed => Icons.favorite_border_rounded,
    };
  }

  static String _labelFor(TripPace pace) {
    return switch (pace) {
      TripPace.relaxed => AppStrings.paceRelaxed,
      TripPace.balanced => AppStrings.paceBalanced,
      TripPace.packed => AppStrings.pacePacked,
    };
  }

  static String _descriptionFor(TripPace pace) {
    return switch (pace) {
      TripPace.relaxed => AppStrings.paceRelaxedDescription,
      TripPace.balanced => AppStrings.paceBalancedDescription,
      TripPace.packed => AppStrings.pacePackedDescription,
    };
  }
}

final class _TripPaceOption extends StatelessWidget {
  const _TripPaceOption({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return RoamlySelectableCard(
      isSelected: selected,
      onTap: onTap,
      semanticLabel: '$label, $description',
      padding: const EdgeInsets.symmetric(
        horizontal: RoamlySpacing.space4,
        vertical: RoamlySpacing.space8,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.06),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(
              selected ? Icons.check_rounded : icon,
              size: 16,
              color: selected ? colors.primary : colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: RoamlySpacing.space4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? colors.primary : colors.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
