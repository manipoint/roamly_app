import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/canonical_location.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/user_preferences.dart';
import 'package:roamly_app/src/features/preferences/domain/repositories/preference_repository.dart';
import 'package:roamly_app/src/features/preferences/presentation/controllers/preference_flow_controller.dart';
import 'package:roamly_app/src/features/preferences/presentation/controllers/preference_draft_controller.dart';
import 'package:roamly_app/src/features/preferences/presentation/widgets/preference_step_scaffold.dart';
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
        travelStyles: const <TravelStyle>{},
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
    required Set<TravelStyle> travelStyles,
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

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    bool continueEnabled() => tester
        .widget<PreferenceStepScaffold>(find.byType(PreferenceStepScaffold))
        .isContinueEnabled;
    expect(continueEnabled(), isFalse);
    Future<void> tapStyle(TravelStyle style) async {
      final card = find.byKey(ValueKey<String>('travel-style-${style.name}'));
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();
    }

    bool selected(TravelStyle style) => tester
        .widget<Semantics>(
          find
              .descendant(
                of: find.byKey(ValueKey<String>('travel-style-${style.name}')),
                matching: find.byType(Semantics),
              )
              .first,
        )
        .properties
        .selected!;
    await tapStyle(TravelStyle.beaches);
    expect(selected(TravelStyle.beaches), isTrue);
    expect(continueEnabled(), isTrue);
    await tapStyle(TravelStyle.beaches);
    expect(selected(TravelStyle.beaches), isFalse);
    expect(continueEnabled(), isFalse);
    for (final style in TravelStyle.values.take(3)) {
      await tapStyle(style);
    }
    await tapStyle(TravelStyle.luxury);
    expect(selected(TravelStyle.luxury), isFalse);
    expect(
      container.read(preferenceDraftControllerProvider).travelStyles.length,
      3,
    );
    expect(tester.takeException(), isNull);

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
