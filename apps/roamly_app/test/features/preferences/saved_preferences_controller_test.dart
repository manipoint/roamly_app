import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/canonical_location.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/user_preferences.dart';
import 'package:roamly_app/src/features/preferences/domain/failures/preference_failure.dart';
import 'package:roamly_app/src/features/preferences/domain/repositories/preference_repository.dart';
import 'package:roamly_app/src/features/preferences/presentation/controllers/saved_preferences_controller.dart';
import 'package:roamly_app/src/features/preferences/presentation/providers/preference_dependency_providers.dart';
import 'package:roamly_app/src/features/preferences/presentation/state/preference_draft.dart';
import 'package:roamly_core/roamly_core.dart';

final _initialPreferences = UserPreferences(
  travelStyle: null,
  interests: <TravelInterest>{},
  budgetTier: null,
  tripPace: null,
  recommendationScope: RecommendationScope.both,
  homeLocation: null,
  onboardingCompleted: false,
  personalizationReady: false,
  onboardingCompletedAt: null,
  createdAt: null,
  updatedAt: null,
);

final _savedPreferences = UserPreferences(
  travelStyle: TravelStyle.nature,
  interests: <TravelInterest>{TravelInterest.hiking},
  budgetTier: BudgetTier.midRange,
  tripPace: TripPace.balanced,
  recommendationScope: RecommendationScope.both,
  homeLocation: null,
  onboardingCompleted: true,
  personalizationReady: true,
  onboardingCompletedAt: null,
  createdAt: null,
  updatedAt: null,
);

final class _FakeRepository implements PreferenceRepository {
  int getCalls = 0;
  int saveCalls = 0;
  int skipCalls = 0;
  Result<UserPreferences> getResult = Success(_initialPreferences);
  Result<UserPreferences> saveResult = Success(_savedPreferences);
  Result<UserPreferences> skipResult = Success(_initialPreferences);
  Completer<Result<UserPreferences>>? saveCompleter;
  PreferenceDraft? capturedDraft;

  @override
  Future<Result<UserPreferences>> getPreferences() async {
    getCalls++;
    return getResult;
  }

  @override
  Future<Result<UserPreferences>> savePreferences({
    required TravelStyle travelStyle,
    required Set<TravelInterest> interests,
    required BudgetTier budgetTier,
    required TripPace tripPace,
    required RecommendationScope recommendationScope,
    required CanonicalLocation? homeLocation,
  }) async {
    saveCalls++;
    capturedDraft = PreferenceDraft(
      travelStyle: travelStyle,
      interests: interests,
      budgetTier: budgetTier,
      tripPace: tripPace,
      recommendationScope: recommendationScope,
      homeLocation: homeLocation,
    );
    return saveCompleter?.future ?? saveResult;
  }

  @override
  Future<Result<UserPreferences>> skipOnboarding() async {
    skipCalls++;
    return skipResult;
  }
}

PreferenceDraft _completeDraft() => PreferenceDraft(
  travelStyle: TravelStyle.nature,
  interests: const <TravelInterest>{TravelInterest.hiking},
  budgetTier: BudgetTier.midRange,
  tripPace: TripPace.balanced,
);

void main() {
  late _FakeRepository repository;
  late ProviderContainer container;
  late ProviderSubscription<AsyncValue<UserPreferences>> subscription;

  setUp(() {
    repository = _FakeRepository();
    container = ProviderContainer(
      overrides: [preferenceRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  void watchController() {
    subscription = container.listen(
      savedPreferencesControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
  }

  test('repository remains untouched until the provider is watched', () {
    expect(repository.getCalls, 0);
  });

  test('first watch loads server-confirmed preferences once', () async {
    watchController();
    final value = await container.read(
      savedPreferencesControllerProvider.future,
    );
    expect(value, same(_initialPreferences));
    expect(repository.getCalls, 1);
  });

  test('a failed initial load is not automatically retried', () async {
    const failure = PreferenceFailure.invalidResponse();
    repository.getResult = const FailureResult(failure);
    watchController();

    await expectLater(
      container.read(savedPreferencesControllerProvider.future),
      throwsA(same(failure)),
    );
    await Future<void>.delayed(Duration.zero);
    expect(repository.getCalls, 1);
    expect(
      container.read(savedPreferencesControllerProvider).error,
      same(failure),
    );
  });

  test('incomplete draft returns false without saving', () async {
    watchController();
    await container.read(savedPreferencesControllerProvider.future);

    final saved = await container
        .read(savedPreferencesControllerProvider.notifier)
        .saveDraft(PreferenceDraft());

    expect(saved, isFalse);
    expect(repository.saveCalls, 0);
    expect(
      container.read(savedPreferencesControllerProvider).value,
      same(_initialPreferences),
    );
  });

  test('complete draft saves and exposes the confirmed response', () async {
    watchController();
    await container.read(savedPreferencesControllerProvider.future);

    final saved = await container
        .read(savedPreferencesControllerProvider.notifier)
        .saveDraft(_completeDraft());

    expect(saved, isTrue);
    expect(repository.saveCalls, 1);
    expect(repository.capturedDraft, _completeDraft());
    expect(
      container.read(savedPreferencesControllerProvider).value,
      same(_savedPreferences),
    );
  });

  test('a second save is ignored while the first request is running', () async {
    watchController();
    await container.read(savedPreferencesControllerProvider.future);
    final completer = Completer<Result<UserPreferences>>();
    repository.saveCompleter = completer;
    final controller = container.read(
      savedPreferencesControllerProvider.notifier,
    );

    final first = controller.saveDraft(_completeDraft());
    final second = await controller.saveDraft(_completeDraft());

    expect(second, isFalse);
    expect(repository.saveCalls, 1);
    completer.complete(Success(_savedPreferences));
    expect(await first, isTrue);
  });

  test('skip stores server state and exposes expected failures', () async {
    watchController();
    await container.read(savedPreferencesControllerProvider.future);
    const failure = PreferenceFailure.invalidResponse();
    repository.skipResult = const FailureResult(failure);

    final skipped = await container
        .read(savedPreferencesControllerProvider.notifier)
        .skipOnboarding();

    expect(skipped, isFalse);
    expect(repository.skipCalls, 1);
    expect(
      container.read(savedPreferencesControllerProvider).error,
      same(failure),
    );
  });

  test('reload performs one explicit retry after an error', () async {
    const failure = PreferenceFailure.invalidResponse();
    repository.getResult = const FailureResult(failure);
    watchController();
    await expectLater(
      container.read(savedPreferencesControllerProvider.future),
      throwsA(same(failure)),
    );
    repository.getResult = Success(_initialPreferences);

    final loaded = await container
        .read(savedPreferencesControllerProvider.notifier)
        .reload();

    expect(loaded, isTrue);
    expect(repository.getCalls, 2);
    expect(
      container.read(savedPreferencesControllerProvider).value,
      same(_initialPreferences),
    );
  });
}
