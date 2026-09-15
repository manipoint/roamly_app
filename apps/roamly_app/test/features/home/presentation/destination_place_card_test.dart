import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_detail.dart';
import 'package:roamly_app/src/features/home/domain/entities/map_location.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/destination_place_card.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/destination_media_image.dart';
import 'package:roamly_ui/roamly_ui.dart';

DestinationPlacePreview _place({
  String? address = '1 Yoyogi Kamizonocho, Shibuya, Tokyo',
  bool isFeatured = true,
}) {
  return DestinationPlacePreview(
    id: '00000000-0000-4000-8000-000000000001',
    slug: 'meiji-shrine',
    name: 'Meiji Shrine',
    placeType: 'religious_site',
    summary: 'Visit a peaceful shrine surrounded by a large forest in Tokyo.',
    location: const MapLocation(latitude: 35.6748, longitude: 139.6996),
    address: address,
    isFeatured: isFeatured,
    coverImage: null,
  );
}

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    DestinationPlacePreview? place,
    VoidCallback? onTap,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: RoamlyTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: DestinationPlaceCard(
                place: place ?? _place(),
                onTap: onTap ?? () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('uses a landscape viewport without distorting the image', (
    tester,
  ) async {
    await pumpCard(tester);

    final aspectRatio = tester.widget<AspectRatio>(
      find.descendant(
        of: find.byType(DestinationPlaceCard),
        matching: find.byType(AspectRatio),
      ),
    );
    final image = tester.widget<DestinationMediaImage>(
      find.descendant(
        of: find.byType(DestinationPlaceCard),
        matching: find.byType(DestinationMediaImage),
      ),
    );

    expect(aspectRatio.aspectRatio, 16 / 9);
    expect(image.boxFit, BoxFit.cover);
  });

  testWidgets('formats the backend place type for display', (tester) async {
    await pumpCard(tester);

    expect(find.text('Religious Site'), findsOneWidget);
  });

  testWidgets('shows optional address and featured state only when present', (
    tester,
  ) async {
    await pumpCard(tester);

    expect(find.text('1 Yoyogi Kamizonocho, Shibuya, Tokyo'), findsOneWidget);
    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);

    await pumpCard(tester, place: _place(address: null, isFeatured: false));

    expect(find.byIcon(Icons.location_on_outlined), findsNothing);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });

  testWidgets('forwards taps and grows safely with large text', (tester) async {
    var tapCount = 0;

    await pumpCard(tester, textScale: 2, onTap: () => tapCount++);
    await tester.tap(find.byType(DestinationPlaceCard));

    expect(tapCount, 1);
    expect(tester.takeException(), isNull);
  });
}
