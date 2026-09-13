import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_ui/roamly_ui.dart';

const _items = [
  RoamlyNavigationItem(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  RoamlyNavigationItem(
    label: 'Trips',
    icon: Icons.luggage_outlined,
    selectedIcon: Icons.luggage,
  ),
  RoamlyNavigationItem(
    label: 'AI Assistant',
    icon: Icons.auto_awesome_outlined,
    selectedIcon: Icons.auto_awesome,
  ),
  RoamlyNavigationItem(
    label: 'Saved',
    icon: Icons.bookmark_outline,
    selectedIcon: Icons.bookmark,
  ),
  RoamlyNavigationItem(
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

void main() {
  Future<void> pumpBar(
    WidgetTester tester,
    ValueChanged<int> onSelected, {
    double bottomInset = 0,
    double textScale = 1,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: RoamlyTheme.light,
        home: MediaQuery(
          data: MediaQueryData(
            padding: EdgeInsets.only(bottom: bottomInset),
            textScaler: TextScaler.linear(textScale),
          ),
          child: RoamlyScaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: RoamlyBottomNavigationBar(
              items: _items,
              selectedIndex: 0,
              onDestinationSelected: onSelected,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'AI circle rises above the border and its raised area is tappable',
    (tester) async {
      int? selected;
      await pumpBar(tester, (index) => selected = index);
      final circle = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
      );
      final surface = find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).border != null &&
            (widget.decoration as BoxDecoration).shape == BoxShape.rectangle,
      );
      final circleRect = tester.getRect(circle);
      final surfaceRect = tester.getRect(surface);
      final barRect = tester.getRect(find.byType(RoamlyBottomNavigationBar));
      expect(circleRect.top, lessThan(surfaceRect.top));
      expect(circleRect.bottom, greaterThan(surfaceRect.top));
      expect(circleRect.top, greaterThanOrEqualTo(barRect.top));
      await tester.tapAt(
        Offset(circleRect.center.dx, (circleRect.top + surfaceRect.top) / 2),
      );
      expect(selected, 2);
      for (final item in _items) {
        expect(find.text(item.label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'safe area is applied once and large labels fit a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpBar(tester, (_) {}, textScale: 2);
      final noInsetHeight = tester
          .getSize(find.byType(RoamlyBottomNavigationBar))
          .height;
      await pumpBar(tester, (_) {}, textScale: 2, bottomInset: 34);
      final insetHeight = tester
          .getSize(find.byType(RoamlyBottomNavigationBar))
          .height;
      expect(insetHeight - noInsetHeight, 34);
      expect(
        tester.getBottomRight(find.text('AI Assistant')).dy,
        lessThanOrEqualTo(640 - 34),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
