import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/presentation/widgets/location_search_field.dart';

void main() {
  Future<void> pumpField(
    WidgetTester tester, {
    required TextEditingController controller,
    ValueChanged<String>? onChanged,
    VoidCallback? onClear,
    bool isLoading = false,
    bool enabled = true,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationSearchField(
            controller: controller,
            onChanged: onChanged ?? (_) {},
            onClear: onClear ?? () {},
            isLoading: isLoading,
            enabled: enabled,
          ),
        ),
      ),
    );
  }

  testWidgets('renders home-city guidance and reports text changes', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? changedValue;
    await pumpField(
      tester,
      controller: controller,
      onChanged: (value) => changedValue = value,
    );

    expect(find.text('Home city'), findsOneWidget);
    expect(find.text('Search for your city'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Lahore');

    expect(changedValue, 'Lahore');
  });

  testWidgets('limits input to the backend query boundary', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpField(tester, controller: controller);

    await tester.enterText(
      find.byType(TextFormField),
      List<String>.filled(121, 'x').join(),
    );

    expect(controller.text, hasLength(120));
  });

  testWidgets('clear action clears text and invokes its callback once', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Lahore');
    addTearDown(controller.dispose);
    var clearCalls = 0;
    await pumpField(
      tester,
      controller: controller,
      onClear: () => clearCalls++,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('location-search-clear')),
    );
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(clearCalls, 1);
  });

  testWidgets('clear action follows programmatic controller changes', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpField(tester, controller: controller);
    expect(
      find.byKey(const ValueKey<String>('location-search-clear')),
      findsNothing,
    );

    controller.text = 'London';
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('location-search-clear')),
      findsOneWidget,
    );

    controller.clear();
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('location-search-clear')),
      findsNothing,
    );
  });

  testWidgets('loading replaces clear action with accessible progress', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = TextEditingController(text: 'Lahore');
    addTearDown(controller.dispose);
    await pumpField(tester, controller: controller, isLoading: true);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Searching locations'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('location-search-clear')),
      findsNothing,
    );

    semantics.dispose();
  });

  testWidgets('disabled state prevents text editing', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpField(tester, controller: controller, enabled: false);

    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), 'Lahore');

    expect(controller.text, isEmpty);
  });
}
