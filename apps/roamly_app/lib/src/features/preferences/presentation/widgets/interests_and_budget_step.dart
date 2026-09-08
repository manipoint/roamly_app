import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../controllers/preference_draft_controller.dart';
import '../controllers/preference_flow_controller.dart';
import 'budget_tier_selector.dart';
import 'preference_section_title.dart';
import 'preference_step_scaffold.dart';
import 'travel_interest_selector.dart';
import 'trip_pace_selector.dart';

/// Coordinates the second onboarding step without owning selector rendering.
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
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PreferenceSectionTitle(title: AppStrings.interestsQuestion),
              const SizedBox(height: RoamlySpacing.space12),
              TravelInterestSelector(
                selected: draft.interests,
                onSelected: (interest) {
                  final changed = draftController.toggleInterest(interest);
                  if (!changed && context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(
                          content: Text(AppStrings.interestLimitMessage),
                        ),
                      );
                  }
                },
              ),
              const SizedBox(height: RoamlySpacing.space24),
              const PreferenceSectionTitle(
                title: AppStrings.budgetPerPerson,
                information: AppStrings.budgetInformation,
              ),
              const SizedBox(height: RoamlySpacing.space8),
              BudgetTierSelector(
                selected: draft.budgetTier,
                onSelected: draftController.selectBudgetTier,
              ),
              const SizedBox(height: RoamlySpacing.space24),
              const PreferenceSectionTitle(
                title: AppStrings.tripPreference,
                information: AppStrings.tripPreferenceInformation,
              ),
              const SizedBox(height: RoamlySpacing.space8),
              TripPaceSelector(
                selected: draft.tripPace,
                onSelected: draftController.selectTripPace,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
