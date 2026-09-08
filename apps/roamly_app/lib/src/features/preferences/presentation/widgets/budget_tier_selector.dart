import 'package:flutter/material.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../domain/entities/preference_types.dart';

/// Single-choice segmented budget control with aligned captions.
final class BudgetTierSelector extends StatelessWidget {
  const BudgetTierSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final BudgetTier? selected;
  final ValueChanged<BudgetTier> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 40,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.78),
            borderRadius: RoamlyRadii.medium,
            border: Border.all(color: colors.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: BudgetTier.values
                .map((tier) {
                  return Expanded(
                    child: _BudgetSegment(
                      key: ValueKey<String>('budget-${tier.name}'),
                      symbol: _symbolFor(tier),
                      label: _labelFor(tier),
                      selected: selected == tier,
                      onTap: () => onSelected(tier),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: RoamlySpacing.space8),
        Row(
          children: BudgetTier.values
              .map((tier) {
                final isSelected = selected == tier;
                return Expanded(
                  child: Text(
                    _labelFor(tier),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? colors.primary
                          : colors.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  static String _labelFor(BudgetTier tier) {
    return switch (tier) {
      BudgetTier.budget => AppStrings.budget,
      BudgetTier.midRange => AppStrings.midRange,
      BudgetTier.premium => AppStrings.premium,
      BudgetTier.luxury => AppStrings.luxury,
    };
  }

  static String _symbolFor(BudgetTier tier) {
    return switch (tier) {
      BudgetTier.budget => r'$',
      BudgetTier.midRange => r'$$',
      BudgetTier.premium => r'$$$',
      BudgetTier.luxury => r'$$$$',
    };
  }
}

final class _BudgetSegment extends StatelessWidget {
  const _BudgetSegment({
    super.key,
    required this.symbol,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String symbol;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: RoamlyRadii.pill,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(colors: [colors.primary, colors.secondary])
                  : null,
              borderRadius: RoamlyRadii.pill,
            ),
            child: Text(
              symbol,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? colors.onPrimary : colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
