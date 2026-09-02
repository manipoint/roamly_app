import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/app/roamly_app.dart';
import 'package:roamly_auth/roamly_auth.dart';

void main() {
  testWidgets('builds the root MaterialApp', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWithBuild((ref, notifier) async {
            return null;
          }),
        ],
        child: const RoamlyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byKey(const ValueKey('unauthenticated-view')), findsOneWidget);
  });
}
