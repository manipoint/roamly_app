import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/canonical_location.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/user_preferences.dart';
import 'package:roamly_app/src/features/preferences/domain/repositories/preference_repository.dart';
import 'package:roamly_app/src/features/preferences/presentation/controllers/preference_flow_controller.dart';
import 'package:roamly_app/src/features/preferences/presentation/providers/preference_dependency_providers.dart';
import 'package:roamly_app/src/features/preferences/presentation/widgets/discovery_scope_step.dart';
import 'package:roamly_app/src/features/preferences/presentation/widgets/interests_and_budget_step.dart';
import 'package:roamly_app/src/features/preferences/presentation/widgets/preference_onboarding_flow.dart';
import 'package:roamly_app/src/features/preferences/presentation/widgets/travel_style_step.dart';
import 'package:roamly_core/roamly_core.dart';

final class _PreferenceRepository implements PreferenceRepository {
  @override
  Future<Result<UserPreferences>> getPreferences() async {
    return Success<UserPreferences>(
      UserPreferences(
        travelStyle: null,
        interests: const <TravelInterest>{},
        budgetTier: null,
        tripPace: null,
        recommendationScope: RecommendationScope.both,
        homeLocation: null,
        onboardingCompleted: false,
        personalizationReady: false,
        onboardingCompletedAt: null,
        createdAt: null,
        updatedAt: null,
      ),
    );
  }

  @override
  Future<Result<UserPreferences>> savePreferences({
    required TravelStyle travelStyle,
    required Set<TravelInterest> interests,
    required BudgetTier budgetTier,
    required TripPace tripPace,
    required RecommendationScope recommendationScope,
    required CanonicalLocation? homeLocation,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<UserPreferences>> skipOnboarding() {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('renders the screen selected by the flow controller', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        preferenceRepositoryProvider.overrideWithValue(_PreferenceRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PreferenceOnboardingFlow()),
      ),
    );

    expect(find.byType(TravelStyleStep), findsOneWidget);

    container
        .read(preferenceFlowControllerProvider.notifier)
        .goTo(PreferenceFlowStep.interestsAndBudget);
    await tester.pump();

    expect(find.byType(InterestsAndBudgetStep), findsOneWidget);
    expect(find.byType(TravelStyleStep), findsNothing);

    container
        .read(preferenceFlowControllerProvider.notifier)
        .goTo(PreferenceFlowStep.discoveryScope);
    await tester.pumpAndSettle();

    expect(find.byType(DiscoveryScopeStep), findsOneWidget);
    expect(find.byType(InterestsAndBudgetStep), findsNothing);
  });
}
