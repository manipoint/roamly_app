import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/data/mappers/preference_enum_mapper.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';

void verifyContract<T extends Enum>(
  String label,
  Map<String, T> expected,
  List<T> values,
  T Function(Object?) decode,
  String Function(T) encode,
) {
  group(label, () {
    test('covers every enum and preserves exact backend spellings', () {
      expect(expected.values.toSet(), values.toSet());
      for (final entry in expected.entries) {
        expect(decode(entry.key), entry.value);
        expect(encode(entry.value), entry.key);
      }
    });

    test('rejects malformed inputs and unsupported values', () {
      for (final value in <Object?>[
        null,
        42,
        true,
        [],
        {},
        '',
        'unknown',
        expected.keys.first.toUpperCase(),
        ' ${expected.keys.first} ',
      ]) {
        expect(() => decode(value), throwsFormatException);
      }
    });
  });
}

void main() {
  verifyContract(
    'travel style',
    {
      'beaches': TravelStyle.beaches,
      'adventure': TravelStyle.adventure,
      'food': TravelStyle.food,
      'luxury': TravelStyle.luxury,
      'nature': TravelStyle.nature,
      'culture': TravelStyle.culture,
    },
    TravelStyle.values,
    PreferenceEnumMapper.travelStyleFromJson,
    PreferenceEnumMapper.travelStyleToJson,
  );

  verifyContract(
    'interests',
    {
      'hiking': TravelInterest.hiking,
      'photography': TravelInterest.photography,
      'nightlife': TravelInterest.nightlife,
      'wellness': TravelInterest.wellness,
      'history': TravelInterest.history,
      'wildlife': TravelInterest.wildlife,
      'shopping': TravelInterest.shopping,
      'local_culture': TravelInterest.localCulture,
      'events': TravelInterest.events,
    },
    TravelInterest.values,
    PreferenceEnumMapper.interestFromJson,
    PreferenceEnumMapper.interestToJson,
  );

  verifyContract(
    'budget tier',
    {
      'budget': BudgetTier.budget,
      'mid_range': BudgetTier.midRange,
      'premium': BudgetTier.premium,
      'luxury': BudgetTier.luxury,
    },
    BudgetTier.values,
    PreferenceEnumMapper.budgetTierFromJson,
    PreferenceEnumMapper.budgetTierToJson,
  );

  verifyContract(
    'trip pace',
    {
      'relaxed': TripPace.relaxed,
      'balanced': TripPace.balanced,
      'packed': TripPace.packed,
    },
    TripPace.values,
    PreferenceEnumMapper.tripPaceFromJson,
    PreferenceEnumMapper.tripPaceToJson,
  );

  verifyContract(
    'recommendation scope',
    {
      'local': RecommendationScope.local,
      'international': RecommendationScope.international,
      'both': RecommendationScope.both,
    },
    RecommendationScope.values,
    PreferenceEnumMapper.recommendationScopeFromJson,
    PreferenceEnumMapper.recommendationScopeToJson,
  );

  test('Dart camelCase names are not accepted as wire values', () {
    expect(
      () => PreferenceEnumMapper.budgetTierFromJson('midRange'),
      throwsFormatException,
    );
    expect(
      () => PreferenceEnumMapper.interestFromJson('localCulture'),
      throwsFormatException,
    );
  });
}
