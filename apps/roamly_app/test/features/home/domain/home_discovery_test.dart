import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_collection.dart';
import 'package:roamly_app/src/features/home/domain/entities/home_discovery.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';

Destination _destination({
  String id = 'destination-1',
  Iterable<TravelStyle> styles = const <TravelStyle>{TravelStyle.culture},
  Iterable<TravelInterest> interests = const <TravelInterest>{
    TravelInterest.history,
  },
}) {
  return Destination(
    id: id,
    slug: 'lahore-pakistan',
    name: 'Lahore',
    countryName: 'Pakistan',
    countryCode: 'PK',
    summary: 'Historic architecture and food culture.',
    imageUri: Uri.parse('https://images.example.test/lahore.webp'),
    imageAlt: 'Lahore Fort at sunset',
    latitude: 31.5204,
    longitude: 74.3587,
    budgetTier: BudgetTier.midRange,
    styles: styles,
    interests: interests,
  );
}

void main() {
  group('Destination', () {
    test('owns immutable style and interest collections', () {
      final styles = <TravelStyle>[TravelStyle.culture];
      final interests = <TravelInterest>[TravelInterest.history];
      final destination = _destination(styles: styles, interests: interests);

      styles.add(TravelStyle.food);
      interests.add(TravelInterest.shopping);

      expect(destination.styles, const <TravelStyle>{TravelStyle.culture});
      expect(destination.interests, const <TravelInterest>{
        TravelInterest.history,
      });
      expect(
        () => destination.styles.add(TravelStyle.food),
        throwsUnsupportedError,
      );
      expect(
        () => destination.interests.add(TravelInterest.shopping),
        throwsUnsupportedError,
      );
    });

    test('equality ignores taxonomy insertion order', () {
      final first = _destination(
        styles: const <TravelStyle>[TravelStyle.culture, TravelStyle.food],
        interests: const <TravelInterest>[
          TravelInterest.history,
          TravelInterest.shopping,
        ],
      );
      final second = _destination(
        styles: const <TravelStyle>[TravelStyle.food, TravelStyle.culture],
        interests: const <TravelInterest>[
          TravelInterest.shopping,
          TravelInterest.history,
        ],
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });

  group('DestinationCollection', () {
    test('copies its input and preserves ranked ordering', () {
      final first = _destination();
      final second = _destination(id: 'destination-2');
      final source = <Destination>[first, second];
      final collection = DestinationCollection(
        kind: DiscoveryCollectionKind.featured,
        items: source,
      );

      source.clear();

      expect(collection.items, <Destination>[first, second]);
      expect(() => collection.items.clear(), throwsUnsupportedError);
      expect(
        collection,
        isNot(
          DestinationCollection(
            kind: DiscoveryCollectionKind.featured,
            items: <Destination>[second, first],
          ),
        ),
      );
    });

    test('collection kind participates in equality', () {
      final item = _destination();

      expect(
        DestinationCollection(
          kind: DiscoveryCollectionKind.featured,
          items: <Destination>[item],
        ),
        isNot(
          DestinationCollection(
            kind: DiscoveryCollectionKind.trending,
            items: <Destination>[item],
          ),
        ),
      );
    });
  });

  group('HomeDiscovery', () {
    test('owns ranked section lists and keeps their order significant', () {
      final first = _destination();
      final second = _destination(id: 'destination-2');
      final suggested = <Destination>[first, second];
      final popular = <Destination>[second, first];
      final spotlight = DestinationCollection(
        kind: DiscoveryCollectionKind.trending,
        items: <Destination>[first],
      );
      final discovery = HomeDiscovery(
        personalizationReady: true,
        suggested: suggested,
        popular: popular,
        spotlight: spotlight,
      );

      suggested.clear();
      popular.clear();

      expect(discovery.suggested, <Destination>[first, second]);
      expect(discovery.popular, <Destination>[second, first]);
      expect(() => discovery.suggested.clear(), throwsUnsupportedError);
      expect(
        discovery,
        isNot(
          HomeDiscovery(
            personalizationReady: true,
            suggested: <Destination>[second, first],
            popular: <Destination>[second, first],
            spotlight: spotlight,
          ),
        ),
      );
    });

    test('equal payloads have equal hash codes', () {
      final item = _destination();
      final spotlight = DestinationCollection(
        kind: DiscoveryCollectionKind.featured,
        items: <Destination>[item],
      );
      final first = HomeDiscovery(
        personalizationReady: false,
        suggested: <Destination>[item],
        popular: const <Destination>[],
        spotlight: spotlight,
      );
      final second = HomeDiscovery(
        personalizationReady: false,
        suggested: <Destination>[item],
        popular: const <Destination>[],
        spotlight: spotlight,
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });
  });
}
