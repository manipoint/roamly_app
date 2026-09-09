import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/preference_flow_controller.dart';
import 'discovery_scope_step.dart';
import 'interests_and_budget_step.dart';
import 'travel_style_step.dart';

/// Coordinates the preference onboarding screens.
///
/// Individual steps own their UI interactions. This widget only maps the
/// current flow state to the corresponding screen.
final class PreferenceOnboardingFlow extends ConsumerWidget {
  const PreferenceOnboardingFlow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(preferenceFlowControllerProvider);

    return switch (step) {
      PreferenceFlowStep.travelStyle => const TravelStyleStep(),
      PreferenceFlowStep.interestsAndBudget => const InterestsAndBudgetStep(),
      PreferenceFlowStep.discoveryScope => const DiscoveryScopeStep(),
    };
  }
}
