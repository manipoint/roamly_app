import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/canonical_location.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/user_preferences.dart';
import 'package:roamly_app/src/features/preferences/domain/failures/location_resolution_failure.dart';
import 'package:roamly_app/src/features/preferences/domain/repositories/location_resolution_repository.dart';
import 'package:roamly_app/src/features/preferences/domain/repositories/preference_repository.dart';
import 'package:roamly_app/src/features/preferences/presentation/controllers/location_search_controller.dart';
import 'package:roamly_app/src/features/preferences/presentation/controllers/preference_draft_controller.dart';
import 'package:roamly_app/src/features/preferences/presentation/controllers/preference_flow_controller.dart';
import 'package:roamly_app/src/features/preferences/presentation/providers/preference_dependency_providers.dart';
import 'package:roamly_app/src/features/preferences/presentation/state/preference_draft.dart';
import 'package:roamly_app/src/features/preferences/presentation/widgets/discovery_scope_step.dart';
import 'package:roamly_app/src/features/preferences/presentation/widgets/location_search_field.dart';
import 'package:roamly_core/roamly_core.dart';

const _lahore = CanonicalLocation(
  provider: 'google',
  providerLocationId: 'lahore-id',
  canonicalName: 'Lahore, Punjab, Pakistan',
  countryCode: 'PK',
  latitude: 31.5204,
  longitude: 74.3587,
);

UserPreferences _preferences({
  bool onboardingCompleted = false,
  RecommendationScope scope = RecommendationScope.both,
  CanonicalLocation? homeLocation,
}) {
  return UserPreferences(
    travelStyle: onboardingCompleted ? TravelStyle.nature : null,
    interests: onboardingCompleted
        ? const <TravelInterest>{TravelInterest.hiking}
        : const <TravelInterest>{},
    budgetTier: onboardingCompleted ? BudgetTier.midRange : null,
    tripPace: onboardingCompleted ? TripPace.balanced : null,
    recommendationScope: scope,
    homeLocation: homeLocation,
    onboardingCompleted: onboardingCompleted,
    personalizationReady: onboardingCompleted,
    onboardingCompletedAt: null,
    createdAt: null,
    updatedAt: null,
  );
}

final class _PreferenceRepository implements PreferenceRepository {
  int saveCalls = 0;
  int skipCalls = 0;
  RecommendationScope? savedScope;
  CanonicalLocation? savedLocation;

  @override
  Future<Result<UserPreferences>> getPreferences() async {
    return Success<UserPreferences>(_preferences());
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
    savedScope = recommendationScope;
    savedLocation = homeLocation;
    return Success<UserPreferences>(
      _preferences(
        onboardingCompleted: true,
        scope: recommendationScope,
        homeLocation: homeLocation,
      ),
    );
  }

  @override
  Future<Result<UserPreferences>> skipOnboarding() async {
    skipCalls++;
    return Success<UserPreferences>(_preferences(onboardingCompleted: true));
  }
}

final class _LocationRequest {
  _LocationRequest(this.query);

  final String query;
  final completer = Completer<Result<List<CanonicalLocation>>>();
}

final class _LocationRepository implements LocationResolutionRepository {
  final List<_LocationRequest> requests = <_LocationRequest>[];

  @override
  Future<Result<List<CanonicalLocation>>> resolve({
    required String query,
    int limit = 5,
  }) {
    final request = _LocationRequest(query);
    requests.add(request);
    return request.completer.future;
  }
}

void main() {
  late ProviderContainer container;
  late ProviderSubscription<PreferenceDraft> draftSubscription;
  late ProviderSubscription<PreferenceFlowStep> flowSubscription;
  late _PreferenceRepository preferenceRepository;
  late _LocationRepository locationRepository;

  setUp(() {
    preferenceRepository = _PreferenceRepository();
    locationRepository = _LocationRepository();
    container = ProviderContainer(
      overrides: [
        preferenceRepositoryProvider.overrideWithValue(preferenceRepository),
        locationResolutionRepositoryProvider.overrideWithValue(
          locationRepository,
        ),
      ],
    );
    draftSubscription = container.listen<PreferenceDraft>(
      preferenceDraftControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    flowSubscription = container.listen<PreferenceFlowStep>(
      preferenceFlowControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );

    final draft = container.read(preferenceDraftControllerProvider.notifier);
    draft.selectTravelStyle(TravelStyle.nature);
    draft.toggleInterest(TravelInterest.hiking);
    draft.selectBudgetTier(BudgetTier.midRange);
    draft.selectTripPace(TripPace.balanced);
    container
        .read(preferenceFlowControllerProvider.notifier)
        .goTo(PreferenceFlowStep.discoveryScope);
  });

  tearDown(() {
    draftSubscription.close();
    flowSubscription.close();
    container.dispose();
  });

  Future<void> pumpStep(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DiscoveryScopeStep()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectLocalScope(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey<String>('recommendation-scope-local')),
    );
    await tester.pump();
  }

  Future<void> resolveLahore(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField), 'Lahore');
    await tester.pump(LocationSearchController.debounceDuration);
    locationRepository.requests.single.completer.complete(
      const Success<List<CanonicalLocation>>(<CanonicalLocation>[_lahore]),
    );
    await tester.pump();
  }

  testWidgets('both scope needs no home location or provider request', (
    tester,
  ) async {
    await pumpStep(tester);

    expect(find.byType(LocationSearchField), findsNothing);
    expect(locationRepository.requests, isEmpty);
    expect(container.read(preferenceDraftControllerProvider).canSubmit, isTrue);
  });

  testWidgets('local scope requires a canonical location selection', (
    tester,
  ) async {
    await pumpStep(tester);
    await selectLocalScope(tester);

    expect(find.byType(LocationSearchField), findsOneWidget);
    expect(
      container.read(preferenceDraftControllerProvider).canSubmit,
      isFalse,
    );

    await resolveLahore(tester);
    final option = find.byKey(
      const ValueKey<String>('location-option-google-lahore-id'),
    );
    await tester.ensureVisible(option);
    await tester.tap(option);
    await tester.pump();

    final draft = container.read(preferenceDraftControllerProvider);
    expect(draft.homeLocation, _lahore);
    expect(draft.canSubmit, isTrue);
    expect(find.text('Lahore, Punjab, Pakistan'), findsWidgets);
  });

  testWidgets('editing selected text clears stale canonical metadata', (
    tester,
  ) async {
    await pumpStep(tester);
    await selectLocalScope(tester);
    await resolveLahore(tester);
    final option = find.byKey(
      const ValueKey<String>('location-option-google-lahore-id'),
    );
    await tester.ensureVisible(option);
    await tester.tap(option);
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'Lahor');

    expect(
      container.read(preferenceDraftControllerProvider).homeLocation,
      isNull,
    );
    container.read(locationSearchControllerProvider.notifier).clear();
  });

  testWidgets('search failure offers one explicit retry', (tester) async {
    await pumpStep(tester);
    await selectLocalScope(tester);
    await tester.enterText(find.byType(TextFormField), 'Lahore');
    await tester.pump(LocationSearchController.debounceDuration);
    locationRepository.requests.single.completer.complete(
      const FailureResult<List<CanonicalLocation>>(
        LocationResolutionFailure.invalidResponse(),
      ),
    );
    await tester.pump();

    final failure = find.byKey(
      const ValueKey<String>('location-search-failure'),
    );
    await tester.ensureVisible(failure);
    expect(failure, findsOneWidget);

    final retry = find.text('Try again');
    await tester.ensureVisible(retry);
    await tester.pump();
    await tester.tap(retry);
    await tester.pump(LocationSearchController.debounceDuration);
    expect(locationRepository.requests, hasLength(2));
  });

  testWidgets('final action saves the complete server payload', (tester) async {
    await pumpStep(tester);
    await selectLocalScope(tester);
    await resolveLahore(tester);
    final option = find.byKey(
      const ValueKey<String>('location-option-google-lahore-id'),
    );
    await tester.ensureVisible(option);
    await tester.tap(option);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('preference-continue')));
    await tester.pump();

    expect(preferenceRepository.saveCalls, 1);
    expect(preferenceRepository.savedScope, RecommendationScope.local);
    expect(preferenceRepository.savedLocation, _lahore);
    expect(
      container.read(preferenceFlowControllerProvider),
      PreferenceFlowStep.discoveryScope,
    );
  });

  testWidgets('back and skip invoke their separate flow operations', (
    tester,
  ) async {
    await pumpStep(tester);

    await tester.tap(find.byKey(const ValueKey<String>('preference-back')));
    expect(
      container.read(preferenceFlowControllerProvider),
      PreferenceFlowStep.interestsAndBudget,
    );

    container
        .read(preferenceFlowControllerProvider.notifier)
        .goTo(PreferenceFlowStep.discoveryScope);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('preference-skip')));
    await tester.pump();

    expect(preferenceRepository.skipCalls, 1);
    expect(preferenceRepository.saveCalls, 0);
  });
}
