import 'package:flutter/material.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../domain/entities/preference_types.dart';

/// Compact multi-select chips matching the preference onboarding design.
final class TravelInterestSelector extends StatelessWidget {
  const TravelInterestSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final Set<TravelInterest> selected;
  final ValueChanged<TravelInterest> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: RoamlySpacing.space8,
      runSpacing: RoamlySpacing.space8,
      children: TravelInterest.values
          .map((interest) {
            return _InterestChip(
              key: ValueKey<String>('interest-${interest.name}'),
              label: _labelFor(interest),
              selected: selected.contains(interest),
              onTap: () => onSelected(interest),
            );
          })
          .toList(growable: false),
    );
  }

  static String _labelFor(TravelInterest interest) {
    return switch (interest) {
      TravelInterest.hiking => AppStrings.interestHiking,
      TravelInterest.photography => AppStrings.interestPhotography,
      TravelInterest.nightlife => AppStrings.interestNightlife,
      TravelInterest.wellness => AppStrings.interestWellness,
      TravelInterest.history => AppStrings.interestHistory,
      TravelInterest.wildlife => AppStrings.interestWildlife,
      TravelInterest.shopping => AppStrings.interestShopping,
      TravelInterest.localCulture => AppStrings.interestLocalCulture,
      TravelInterest.events => AppStrings.interestEvents,
    };
  }
}

final class _InterestChip extends StatelessWidget {
  const _InterestChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      avatar: selected
          ? CircleAvatar(
              radius: 8,
              backgroundColor: colors.primary,
              child: Icon(Icons.check, size: 11, color: colors.onPrimary),
            )
          : null,
      selectedColor: colors.primary.withValues(alpha: 0.08),
      backgroundColor: colors.surface.withValues(alpha: 0.72),
      side: BorderSide(
        color: selected
            ? colors.primary
            : colors.outlineVariant.withValues(alpha: 0.78),
      ),
      shape: const StadiumBorder(),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: selected ? colors.primary : colors.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}
