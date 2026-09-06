import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/canonical_location.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/user_preferences.dart';
import 'package:roamly_app/src/features/preferences/domain/failures/preference_failure.dart';
import 'package:roamly_app/src/features/preferences/domain/repositories/preference_repository.dart';
import 'package:roamly_app/src/features/preferences/presentation/providers/preference_dependency_providers.dart';
import 'package:roamly_app/src/features/preferences/presentation/widgets/preference_gate.dart';
import 'package:roamly_core/roamly_core.dart';

UserPreferences _preferences({required bool completed}) {
  return UserPreferences(
    travelStyle: null,
    interests: const <TravelInterest>{},
    budgetTier: null,
    tripPace: null,
    recommendationScope: RecommendationScope.both,
    homeLocation: null,
    onboardingCompleted: completed,
    personalizationReady: false,
    onboardingCompletedAt: null,
    createdAt: null,
    updatedAt: null,
  );
}

final class _Repository implements PreferenceRepository {
  int getCalls = 0;
  Result<UserPreferences> getResult = Success(_preferences(completed: false));
  Completer<Result<UserPreferences>>? getCompleter;

  @override
  Future<Result<UserPreferences>> getPreferences() async {
    getCalls++;
    return getCompleter?.future ?? getResult;
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
  late _Repository repository;

  setUp(() {
    repository = _Repository();
  });

  Future<void> pumpGate(WidgetTester tester) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [preferenceRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: PreferenceGate(
            authenticatedChild: Text(
              'authenticated-content',
              key: ValueKey<String>('authenticated-content'),
            ),
            onboardingChild: Text(
              'onboarding-content',
              key: ValueKey<String>('onboarding-content'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows lightweight loading UI while preferences are pending', (
    tester,
  ) async {
    repository.getCompleter = Completer<Result<UserPreferences>>();
    await pumpGate(tester);
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('preference-loading')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('authenticated-content')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('onboarding-content')),
      findsNothing,
    );
    expect(repository.getCalls, 1);
  });

  testWidgets('shows onboarding when server status is incomplete', (
    tester,
  ) async {
    await pumpGate(tester);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('onboarding-content')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('authenticated-content')),
      findsNothing,
    );
  });

  testWidgets('reveals authenticated content after completed onboarding', (
    tester,
  ) async {
    repository.getResult = Success(_preferences(completed: true));
    await pumpGate(tester);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('authenticated-content')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('onboarding-content')),
      findsNothing,
    );
  });

  testWidgets('initial failure offers one explicit retry', (tester) async {
    repository.getResult = const FailureResult(
      PreferenceFailure.invalidResponse(),
    );
    await pumpGate(tester);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('preference-load-failure')),
      findsOneWidget,
    );
    expect(repository.getCalls, 1);

    repository.getResult = Success(_preferences(completed: false));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(repository.getCalls, 2);
    expect(
      find.byKey(const ValueKey<String>('onboarding-content')),
      findsOneWidget,
    );
  });
}
