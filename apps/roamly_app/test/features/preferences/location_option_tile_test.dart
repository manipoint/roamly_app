import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/canonical_location.dart';
import 'package:roamly_app/src/features/preferences/presentation/widgets/location_option_tile.dart';

const _location = CanonicalLocation(
  provider: 'google',
  providerLocationId: 'lahore-id',
  canonicalName: 'Lahore, Punjab, Pakistan',
  countryCode: 'PK',
  latitude: 31.5204,
  longitude: 74.3587,
);

void main() {
  Future<void> pumpTile(
    WidgetTester tester, {
    CanonicalLocation location = _location,
    bool isSelected = false,
    VoidCallback? onTap,
    double width = 390,
    double textScale = 1,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 800),
                textScaler: TextScaler.linear(textScale),
              ),
              child: SizedBox(
                width: width,
                child: LocationOptionTile(
                  location: location,
                  isSelected: isSelected,
                  onTap: onTap ?? () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders canonical user-facing fields with a stable key', (
    tester,
  ) async {
    await pumpTile(tester);

    expect(find.text('Lahore, Punjab, Pakistan'), findsOneWidget);
    expect(find.text('PK'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('location-option-google-lahore-id')),
      findsOneWidget,
    );
    expect(find.text('lahore-id'), findsNothing);
    expect(find.text('31.5204'), findsNothing);
  });

  testWidgets('invokes the supplied callback', (tester) async {
    var taps = 0;
    await pumpTile(tester, onTap: () => taps++);

    await tester.tap(
      find.byKey(const ValueKey<String>('location-option-google-lahore-id')),
    );

    expect(taps, 1);
  });

  testWidgets('exposes selected semantics and selected affordance', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await pumpTile(tester, isSelected: true);

    final node = tester.getSemantics(
      find.byKey(const ValueKey<String>('location-option-google-lahore-id')),
    );
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.flagsCollection.isSelected, ui.Tristate.isTrue);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsNothing);

    semantics.dispose();
  });

  testWidgets('unselected tile exposes navigation affordance', (tester) async {
    await pumpTile(tester);

    expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('long names and large text do not overflow narrow layouts', (
    tester,
  ) async {
    await pumpTile(
      tester,
      width: 280,
      textScale: 2,
      location: const CanonicalLocation(
        provider: 'google',
        providerLocationId: 'long-id',
        canonicalName:
            'A very long canonical location name with regional context',
        countryCode: 'GB',
        latitude: 51.5072,
        longitude: -0.1276,
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
