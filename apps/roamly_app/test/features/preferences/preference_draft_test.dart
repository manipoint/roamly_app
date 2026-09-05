import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/canonical_location.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';
import 'package:roamly_app/src/features/preferences/presentation/controllers/preference_draft_controller.dart';
import 'package:roamly_app/src/features/preferences/presentation/state/preference_draft.dart';

void main() {
  const location = CanonicalLocation(
    provider: 'google',
    providerLocationId: 'lahore-id',
    canonicalName: 'Lahore, Pakistan',
    countryCode: 'PK',
    latitude: 31.5204,
    longitude: 74.3587,
  );

  test('draft copies interests and exposes an immutable collection', () {
    final source = <TravelInterest>{TravelInterest.hiking};
    final draft = PreferenceDraft(interests: source);
    source.clear();
    expect(draft.interests, {TravelInterest.hiking});
    expect(() => draft.interests.clear(), throwsUnsupportedError);
  });

  test('interest order does not change equality or hash code', () {
    final first = PreferenceDraft(
      interests: [TravelInterest.hiking, TravelInterest.history],
    );
    final second = PreferenceDraft(
      interests: [TravelInterest.history, TravelInterest.hiking],
    );
    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('complete selections require home for geographic filtering', () {
    final draft = PreferenceDraft(
      travelStyle: TravelStyle.nature,
      interests: [TravelInterest.hiking],
      budgetTier: BudgetTier.budget,
      tripPace: TripPace.relaxed,
    );
    expect(draft.canSubmit, isTrue);
    for (final scope in [
      RecommendationScope.local,
      RecommendationScope.international,
    ]) {
      final scoped = draft.copyWith(recommendationScope: scope);
      expect(scoped.canSubmit, isFalse);
      expect(scoped.copyWith(homeLocation: location).canSubmit, isTrue);
    }
    expect(draft.copyWith(interests: []).canSubmit, isFalse);
    expect(
      draft.copyWith(interests: TravelInterest.values.take(6)).canSubmit,
      isFalse,
    );
  });

  test('clearing home leaves the original draft unchanged', () {
    final original = PreferenceDraft(homeLocation: location);
    expect(original.copyWith(clearHomeLocation: true).homeLocation, isNull);
    expect(original.homeLocation, location);
    expect(
      () => original.copyWith(clearHomeLocation: true, homeLocation: location),
      throwsArgumentError,
    );
  });

  group('PreferenceDraftController', () {
    late ProviderContainer container;
    late PreferenceDraftController controller;

    setUp(() {
      container = ProviderContainer();
      container.listen(preferenceDraftControllerProvider, (_, _) {});
      controller = container.read(preferenceDraftControllerProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('rejects sixth interest but permits removal and replacement', () {
      for (final interest in TravelInterest.values.take(5)) {
        expect(controller.toggleInterest(interest), isTrue);
      }
      final before = container.read(preferenceDraftControllerProvider);
      final sixth = TravelInterest.values[5];
      expect(controller.toggleInterest(sixth), isFalse);
      expect(container.read(preferenceDraftControllerProvider), same(before));
      expect(controller.toggleInterest(TravelInterest.hiking), isTrue);
      expect(controller.toggleInterest(sixth), isTrue);
      expect(before.interests, contains(TravelInterest.hiking));
    });

    test('reset clears all selections including home and scope', () {
      controller.selectTravelStyle(TravelStyle.nature);
      controller.toggleInterest(TravelInterest.hiking);
      controller.selectBudgetTier(BudgetTier.budget);
      controller.selectTripPace(TripPace.relaxed);
      controller.selectRecommendationScope(RecommendationScope.local);
      controller.selectHomeLocation(location);
      expect(
        container.read(preferenceDraftControllerProvider).canSubmit,
        isTrue,
      );
      controller.clearHomeLocation();
      expect(
        container.read(preferenceDraftControllerProvider).canSubmit,
        isFalse,
      );
      controller.reset();
      expect(
        container.read(preferenceDraftControllerProvider),
        PreferenceDraft(),
      );
    });

    test('invalidation removes selections from a previous flow', () {
      controller.selectHomeLocation(location);
      container.invalidate(preferenceDraftControllerProvider);
      expect(
        container.read(preferenceDraftControllerProvider),
        PreferenceDraft(),
      );
    });
  });
}
