import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';
import 'package:roamly_app/src/features/preferences/presentation/widgets/recommendation_scope_selector.dart';

void main() {
  Future<void> pumpSelector(
    WidgetTester tester, {
    required RecommendationScope selected,
    required ValueChanged<RecommendationScope> onSelected,
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
                child: RecommendationScopeSelector(
                  selected: selected,
                  onSelected: onSelected,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders all choices and exposes the selected option', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await pumpSelector(
      tester,
      selected: RecommendationScope.international,
      onSelected: (_) {},
    );

    expect(find.text('Local'), findsOneWidget);
    expect(find.text('International'), findsOneWidget);
    expect(find.text('Both'), findsOneWidget);

    final selectedNode = tester.getSemantics(
      find.byKey(const ValueKey<String>('recommendation-scope-international')),
    );
    expect(selectedNode.flagsCollection.isButton, isTrue);
    expect(selectedNode.flagsCollection.isSelected, ui.Tristate.isTrue);
    semantics.dispose();
  });

  testWidgets('reports the exact tapped domain selection', (tester) async {
    RecommendationScope? selection;
    await pumpSelector(
      tester,
      selected: RecommendationScope.both,
      onSelected: (value) => selection = value,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('recommendation-scope-local')),
    );

    expect(selection, RecommendationScope.local);
  });

  testWidgets('uses a horizontal layout at normal phone width', (tester) async {
    await pumpSelector(
      tester,
      selected: RecommendationScope.both,
      onSelected: (_) {},
    );

    final local = tester.getTopLeft(
      find.byKey(const ValueKey<String>('recommendation-scope-local')),
    );
    final international = tester.getTopLeft(
      find.byKey(const ValueKey<String>('recommendation-scope-international')),
    );
    final both = tester.getTopLeft(
      find.byKey(const ValueKey<String>('recommendation-scope-both')),
    );

    expect(international.dx, greaterThan(local.dx));
    expect(both.dx, greaterThan(international.dx));
    expect(international.dy, closeTo(local.dy, 0.1));
    expect(both.dy, closeTo(local.dy, 0.1));
  });

  testWidgets('stacks choices on narrow layouts', (tester) async {
    await pumpSelector(
      tester,
      width: 320,
      selected: RecommendationScope.both,
      onSelected: (_) {},
    );

    final local = tester.getTopLeft(
      find.byKey(const ValueKey<String>('recommendation-scope-local')),
    );
    final international = tester.getTopLeft(
      find.byKey(const ValueKey<String>('recommendation-scope-international')),
    );
    final both = tester.getTopLeft(
      find.byKey(const ValueKey<String>('recommendation-scope-both')),
    );

    expect(international.dy, greaterThan(local.dy));
    expect(both.dy, greaterThan(international.dy));
    expect(international.dx, closeTo(local.dx, 0.1));
    expect(both.dx, closeTo(local.dx, 0.1));
  });

  testWidgets('large accessibility text does not overflow', (tester) async {
    await pumpSelector(
      tester,
      textScale: 2,
      selected: RecommendationScope.local,
      onSelected: (_) {},
    );

    expect(tester.takeException(), isNull);
  });
}
