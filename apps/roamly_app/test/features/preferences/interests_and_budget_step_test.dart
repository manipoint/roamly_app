import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';
import 'package:roamly_app/src/features/preferences/presentation/controllers/preference_draft_controller.dart';
import 'package:roamly_app/src/features/preferences/presentation/controllers/preference_flow_controller.dart';
import 'package:roamly_app/src/features/preferences/presentation/widgets/budget_tier_selector.dart';
import 'package:roamly_app/src/features/preferences/presentation/widgets/interests_and_budget_step.dart';
import 'package:roamly_app/src/features/preferences/presentation/widgets/trip_pace_selector.dart';

void main() {
  late ProviderContainer container;
  late ProviderSubscription<PreferenceFlowStep> flowSubscription;

  setUp(() {
    container = ProviderContainer();
    flowSubscription = container.listen(
      preferenceFlowControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    container
        .read(preferenceFlowControllerProvider.notifier)
        .goTo(PreferenceFlowStep.interestsAndBudget);
  });

  tearDown(() {
    flowSubscription.close();
    container.dispose();
  });

  Future<void> pumpStep(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: InterestsAndBudgetStep()),
      ),
    );
    await tester.pump();
  }

  testWidgets('requires an interest, budget, and pace before continuing', (
    tester,
  ) async {
    await pumpStep(tester);

    await tester.tap(
      find.byKey(const ValueKey<String>('preference-continue')),
      warnIfMissed: false,
    );
    expect(
      container.read(preferenceFlowControllerProvider),
      PreferenceFlowStep.interestsAndBudget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('interest-hiking')));
    await tester.tap(find.byKey(const ValueKey<String>('budget-midRange')));
    final balancedPace = find.byKey(const ValueKey<String>('pace-balanced'));
    await tester.ensureVisible(balancedPace);
    await tester.pumpAndSettle();
    await tester.tap(balancedPace);
    await tester.pump();

    final draft = container.read(preferenceDraftControllerProvider);
    expect(draft.interests, <TravelInterest>{TravelInterest.hiking});
    expect(draft.budgetTier, BudgetTier.midRange);
    expect(draft.tripPace, TripPace.balanced);
    expect(draft.isInterestsAndBudgetComplete, isTrue);

    await tester.tap(find.byKey(const ValueKey<String>('preference-continue')));
    expect(
      container.read(preferenceFlowControllerProvider),
      PreferenceFlowStep.discoveryScope,
    );
  });

  testWidgets('an interest can be deselected', (tester) async {
    await pumpStep(tester);
    final hiking = find.byKey(const ValueKey<String>('interest-hiking'));

    await tester.tap(hiking);
    await tester.pump();
    await tester.tap(hiking);
    await tester.pump();

    expect(
      container.read(preferenceDraftControllerProvider).interests,
      isEmpty,
    );
  });

  testWidgets('limits interest selection to five and explains the limit', (
    tester,
  ) async {
    await pumpStep(tester);

    for (final interest in TravelInterest.values.take(5)) {
      await tester.tap(
        find.byKey(ValueKey<String>('interest-${interest.name}')),
      );
      await tester.pump();
    }

    final sixth = TravelInterest.values[5];
    await tester.tap(find.byKey(ValueKey<String>('interest-${sixth.name}')));
    await tester.pump();

    expect(
      container.read(preferenceDraftControllerProvider).interests.length,
      5,
    );
    expect(find.text('You can select up to 5 interests.'), findsOneWidget);
  });

  testWidgets('back returns to travel style', (tester) async {
    await pumpStep(tester);

    await tester.tap(find.byKey(const ValueKey<String>('preference-back')));

    expect(
      container.read(preferenceFlowControllerProvider),
      PreferenceFlowStep.travelStyle,
    );
  });

  testWidgets('uses compact selectors and clears the fixed bottom action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpStep(tester);

    expect(find.text('0/5'), findsNothing);
    expect(find.byType(GridView), findsNothing);
    expect(
      tester.getSize(find.byType(BudgetTierSelector)).height,
      lessThan(70),
    );
    expect(tester.getSize(find.byType(TripPaceSelector)).height, 84);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    final paceBottom = tester.getBottomLeft(find.byType(TripPaceSelector)).dy;
    final buttonTop = tester
        .getTopLeft(find.byKey(const ValueKey<String>('preference-continue')))
        .dy;

    expect(paceBottom, lessThanOrEqualTo(buttonTop));
    expect(tester.takeException(), isNull);
  });
}
