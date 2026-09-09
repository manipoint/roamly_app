import 'package:flutter/material.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../../../localization/app_strings.dart';
import '../../domain/entities/preference_types.dart';

final class RecommendationScopeSelector extends StatelessWidget {
  const RecommendationScopeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final RecommendationScope selected;
  final ValueChanged<RecommendationScope> onSelected;

  static const List<_ScopeOption> _options = <_ScopeOption>[
    _ScopeOption(
      scope: RecommendationScope.local,
      icon: Icons.near_me_outlined,
      label: AppStrings.localTrips,
      description: AppStrings.localTripsDescription,
    ),
    _ScopeOption(
      scope: RecommendationScope.international,
      icon: Icons.flight_takeoff_outlined,
      label: AppStrings.internationalTrips,
      description: AppStrings.internationalTripsDescription,
    ),
    _ScopeOption(
      scope: RecommendationScope.both,
      icon: Icons.public_outlined,
      label: AppStrings.bothTripScopes,
      description: AppStrings.bothTripScopesDescription,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 340) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _options
                .map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: RoamlySpacing.space8,
                    ),
                    child: _ScopeCard(
                      option: option,
                      isSelected: selected == option.scope,
                      onSelected: onSelected,
                    ),
                  ),
                )
                .toList(growable: false),
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < _options.length; index++) ...[
                if (index > 0) const SizedBox(width: RoamlySpacing.space8),
                Expanded(
                  child: _ScopeCard(
                    option: _options[index],
                    isSelected: selected == _options[index].scope,
                    onSelected: onSelected,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

final class _ScopeCard extends StatelessWidget {
  const _ScopeCard({
    required this.option,
    required this.isSelected,
    required this.onSelected,
  });

  final _ScopeOption option;
  final bool isSelected;
  final ValueChanged<RecommendationScope> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return RoamlySelectableCard(
      key: ValueKey<String>('recommendation-scope-${option.scope.name}'),
      isSelected: isSelected,
      onTap: () => onSelected(option.scope),
      semanticLabel: option.label,
      padding: const EdgeInsets.all(RoamlySpacing.space12),
      constraints: const BoxConstraints(minHeight: 104),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            option.icon,
            color: isSelected ? colors.primary : colors.onSurfaceVariant,
          ),
          const SizedBox(height: RoamlySpacing.space8),
          Text(
            option.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: RoamlySpacing.space4),
          Text(
            option.description,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

final class _ScopeOption {
  const _ScopeOption({
    required this.scope,
    required this.icon,
    required this.label,
    required this.description,
  });

  final RecommendationScope scope;
  final IconData icon;
  final String label;
  final String description;
}
