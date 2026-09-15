import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/destination_location_button.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  testWidgets('renders location and forwards the map action', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: RoamlyTheme.light,
        home: Scaffold(
          body: DestinationLocationButton(
            label: 'Shibuya, Tokyo',
            onTap: () => tapCount++,
          ),
        ),
      ),
    );

    expect(find.text('Shibuya, Tokyo'), findsOneWidget);
    expect(find.text('View on map'), findsOneWidget);
    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);

    await tester.tap(find.byType(DestinationLocationButton));
    expect(tapCount, 1);
  });
}
