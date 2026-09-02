import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_ui/roamly_ui.dart';

void main() {
  testWidgets('button remains usable on a compact screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: RoamlyTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(RoamlySpacing.space16),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {},
                      child: const Text('Continue planning my trip'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(48),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });
}
