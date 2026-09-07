import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../domain/entities/preference_types.dart';
import '../controllers/preference_draft_controller.dart';
import '../controllers/preference_flow_controller.dart';
import 'preference_step_scaffold.dart';

/// Collects the preference signals used for deterministic recommendations.
final class InterestsAndBudgetStep extends ConsumerWidget {
  const InterestsAndBudgetStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowStep = ref.watch(preferenceFlowControllerProvider);
    final draft = ref.watch(preferenceDraftControllerProvider);
    final draftController = ref.read(
      preferenceDraftControllerProvider.notifier,
    );

    return PreferenceStepScaffold(
      currentStep: flowStep.index,
      stepCount: PreferenceFlowStep.values.length,
      title: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: AppStrings.interestsBudgetTitlePrefix),
            TextSpan(
              text: AppStrings.interestsBudgetTitleEmphasis,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
      description: AppStrings.interestsBudgetDescription,
      isContinueEnabled: draft.isInterestsAndBudgetComplete,
      onBack: () {
        ref.read(preferenceFlowControllerProvider.notifier).previous();
      },
      onContinue: () {
        ref.read(preferenceFlowControllerProvider.notifier).next();
      },
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionTitle(
                title: AppStrings.interestsQuestion,
                trailing: '${draft.interests.length}/5',
              ),
              const SizedBox(height: RoamlySpacing.space12),
              Wrap(
                spacing: RoamlySpacing.space8,
                runSpacing: RoamlySpacing.space8,
                children: TravelInterest.values
                    .map((interest) {
                      return _InterestChip(
                        key: ValueKey<String>('interest-${interest.name}'),
                        label: _interestLabel(interest),
                        selected: draft.interests.contains(interest),
                        onSelected: () {
                          final changed = draftController.toggleInterest(
                            interest,
                          );
                          if (!changed && context.mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    AppStrings.interestLimitMessage,
                                  ),
                                ),
                              );
                          }
                        },
                      );
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: RoamlySpacing.space32),
              const _SectionTitle(title: AppStrings.budgetPerPerson),
              const SizedBox(height: RoamlySpacing.space12),
              SizedBox(
                height: 82,
                child: _BudgetSelector(
                  selected: draft.budgetTier,
                  onSelected: draftController.selectBudgetTier,
                ),
              ),
              const SizedBox(height: RoamlySpacing.space32),
              const _SectionTitle(title: AppStrings.tripPreference),
              const SizedBox(height: RoamlySpacing.space12),
              _PaceSelector(
                selected: draft.tripPace,
                onSelected: draftController.selectTripPace,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _interestLabel(TravelInterest interest) {
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

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (trailing case final value?)
          Text(value, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

final class _InterestChip extends StatelessWidget {
  const _InterestChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: true,
      checkmarkColor: colors.primary,
      selectedColor: colors.primaryContainer,
      backgroundColor: colors.surface,
      side: BorderSide(
        color: selected ? colors.primary : colors.outlineVariant,
      ),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}

final class _BudgetSelector extends StatelessWidget {
  const _BudgetSelector({required this.selected, required this.onSelected});

  final BudgetTier? selected;
  final ValueChanged<BudgetTier> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final tier in BudgetTier.values)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: tier == BudgetTier.values.last
                    ? 0
                    : RoamlySpacing.space8,
              ),
              child: _BudgetOption(
                key: ValueKey<String>('budget-${tier.name}'),
                label: _budgetLabel(tier),
                symbol: _budgetSymbol(tier),
                selected: selected == tier,
                onTap: () => onSelected(tier),
              ),
            ),
          ),
      ],
    );
  }

  static String _budgetLabel(BudgetTier tier) {
    return switch (tier) {
      BudgetTier.budget => AppStrings.budget,
      BudgetTier.midRange => AppStrings.midRange,
      BudgetTier.premium => AppStrings.premium,
      BudgetTier.luxury => AppStrings.luxury,
    };
  }

  static String _budgetSymbol(BudgetTier tier) {
    return switch (tier) {
      BudgetTier.budget => r'$',
      BudgetTier.midRange => r'$$',
      BudgetTier.premium => r'$$$',
      BudgetTier.luxury => r'$$$$',
    };
  }
}

final class _BudgetOption extends StatelessWidget {
  const _BudgetOption({
    super.key,
    required this.label,
    required this.symbol,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String symbol;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return RoamlySelectableCard(
      semanticLabel: label,
      isSelected: selected,
      onTap: onTap,
      padding: const EdgeInsets.all(RoamlySpacing.space8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            symbol,
            maxLines: 1,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: selected ? colors.primary : colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: RoamlySpacing.space4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

final class _PaceSelector extends StatelessWidget {
  const _PaceSelector({required this.selected, required this.onSelected});

  final TripPace? selected;
  final ValueChanged<TripPace> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final oneColumn = constraints.maxWidth < 330;
        return GridView.count(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: oneColumn ? 1 : 3,
          crossAxisSpacing: RoamlySpacing.space8,
          mainAxisSpacing: RoamlySpacing.space8,
          childAspectRatio: oneColumn ? 3.5 : 1.05,
          children: TripPace.values
              .map((pace) {
                return _PaceOption(
                  key: ValueKey<String>('pace-${pace.name}'),
                  icon: _paceIcon(pace),
                  label: _paceLabel(pace),
                  description: _paceDescription(pace),
                  selected: selected == pace,
                  onTap: () => onSelected(pace),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }

  static IconData _paceIcon(TripPace pace) {
    return switch (pace) {
      TripPace.relaxed => Icons.access_time_rounded,
      TripPace.balanced => Icons.explore_outlined,
      TripPace.packed => Icons.favorite_border_rounded,
    };
  }

  static String _paceLabel(TripPace pace) {
    return switch (pace) {
      TripPace.relaxed => AppStrings.paceRelaxed,
      TripPace.balanced => AppStrings.paceBalanced,
      TripPace.packed => AppStrings.pacePacked,
    };
  }

  static String _paceDescription(TripPace pace) {
    return switch (pace) {
      TripPace.relaxed => AppStrings.paceRelaxedDescription,
      TripPace.balanced => AppStrings.paceBalancedDescription,
      TripPace.packed => AppStrings.pacePackedDescription,
    };
  }
}

final class _PaceOption extends StatelessWidget {
  const _PaceOption({
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
      padding: const EdgeInsets.all(RoamlySpacing.space8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: selected ? colors.primary : colors.onSurfaceVariant,
          ),
          const SizedBox(height: RoamlySpacing.space4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
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
