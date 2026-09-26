import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_content_types.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message_delivery_state.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_rich_content.dart';
import 'package:roamly_app/src/features/assistant/presentation/widgets/assistant_hotel_card_view.dart';
import 'package:roamly_app/src/features/assistant/presentation/widgets/assistant_content_carousel.dart';
import 'package:roamly_app/src/features/assistant/presentation/widgets/assistant_message_tile.dart';
import 'package:roamly_app/src/features/assistant/presentation/widgets/assistant_place_card_view.dart';
import 'package:roamly_ui/roamly_ui.dart';

AssistantHotelCard _hotel({
  String id = 'hotel-1',
  AssistantMoneyQualifier qualifier = AssistantMoneyQualifier.perNight,
  bool details = true,
  double score = 9.4,
}) => AssistantHotelCard(
  id: id,
  name: 'Hotel $id',
  location: 'Kyoto, Japan',
  category: details ? 'Luxury' : null,
  rating: details ? 5 : null,
  reviewScore: details ? score : null,
  price: details
      ? AssistantMoney(
          amount: '9007199254740993.01',
          currency: 'JPY',
          qualifier: qualifier,
        )
      : null,
  image: null,
  expiresAt: null,
);

const _place = AssistantPlaceCard(
  id: 'gion',
  name: 'Gion',
  location: 'Kyoto',
  subtitle: 'Historic district',
  image: null,
  latitude: null,
  longitude: null,
);

AssistantMessage _message({
  List<AssistantContentSection>? sections,
  bool user = false,
}) {
  final time = DateTime.utc(2026, 10, 1);
  return AssistantMessage(
    id: '00000000-0000-4000-8000-000000000001',
    conversationLocalId: '00000000-0000-4000-8000-000000000002',
    clientMessageId: '00000000-0000-4000-8000-000000000003',
    assistantMessageId: user ? null : '00000000-0000-4000-8000-000000000001',
    author: user
        ? AssistantMessageAuthor.user
        : AssistantMessageAuthor.assistant,
    content: 'Your travel suggestions.',
    deliveryState: AssistantMessageDeliveryState.completed,
    createdAt: time,
    updatedAt: time,
    richContent: sections == null
        ? null
        : AssistantRichContent(sections: sections),
  );
}

Widget _app(Widget child, {double scale = 1, bool dark = false}) => MaterialApp(
  theme: dark ? RoamlyTheme.dark : RoamlyTheme.light,
  home: Scaffold(
    body: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 300, child: child),
        ),
      ),
    ),
  ),
);

void main() {
  for (final entry in {
    AssistantMoneyQualifier.total: 'JPY 9007199254740993.01 total',
    AssistantMoneyQualifier.perNight: 'JPY 9007199254740993.01 per night',
    AssistantMoneyQualifier.from: 'From JPY 9007199254740993.01',
  }.entries) {
    testWidgets('hotel renders exact price for ${entry.key}', (tester) async {
      await tester.pumpWidget(
        _app(AssistantHotelCardView(hotelCard: _hotel(qualifier: entry.key))),
      );
      expect(find.text(entry.value), findsOneWidget);
      expect(find.text('Quoted price'), findsOneWidget);
      expect(find.text('5-star hotel'), findsOneWidget);
      expect(find.text('9.4 / 10 guest rating'), findsOneWidget);
      expect(find.text('Luxury'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'hotel omits absent optional details and shows image placeholder',
    (tester) async {
      await tester.pumpWidget(
        _app(AssistantHotelCardView(hotelCard: _hotel(details: false))),
      );
      expect(find.text('Hotel hotel-1'), findsOneWidget);
      expect(find.text('Kyoto, Japan'), findsOneWidget);
      expect(find.text('Quoted price'), findsNothing);
      expect(find.textContaining('guest rating'), findsNothing);
      expect(find.textContaining('star hotel'), findsNothing);
      expect(find.byIcon(Icons.landscape_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('integral guest score is displayed without decimal suffix', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(AssistantHotelCardView(hotelCard: _hotel(score: 10))),
    );
    expect(find.text('10 / 10 guest rating'), findsOneWidget);
  });

  testWidgets(
    'hotel card grows for large text in dark theme without overflow',
    (tester) async {
      final card = AssistantHotelCardView(hotelCard: _hotel());
      await tester.pumpWidget(_app(card));
      final initialHeight = tester
          .getSize(find.byType(AssistantHotelCardView))
          .height;
      await tester.pumpWidget(_app(card, scale: 3, dark: true));
      expect(
        tester.getSize(find.byType(AssistantHotelCardView)).height,
        greaterThan(initialHeight),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('hotel carousel scrolls to its final card', (tester) async {
    await tester.pumpWidget(
      _app(
        AssistantMessageTile(
          message: _message(
            sections: [
              AssistantHotelCarousel(
                id: 'hotels',
                title: 'Hotels',
                items: List.generate(
                  5,
                  (i) => _hotel(id: '$i', details: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final scroll = find.byWidgetPredicate(
      (widget) =>
          widget is SingleChildScrollView &&
          widget.scrollDirection == Axis.horizontal,
    );
    await tester.ensureVisible(scroll);
    await tester.pumpAndSettle();
    await tester.drag(scroll, const Offset(-1400, 0));
    await tester.pumpAndSettle();
    expect(find.text('Hotel 4').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tile preserves backend section order and forwards place tap', (
    tester,
  ) async {
    AssistantPlaceCard? selected;
    await tester.pumpWidget(
      _app(
        AssistantMessageTile(
          message: _message(
            sections: [
              AssistantHotelCarousel(
                id: 'hotels',
                title: 'Hotels first',
                items: [_hotel(details: false)],
              ),
              AssistantPlaceCarousel(
                id: 'places',
                title: 'Places second',
                items: [_place],
              ),
            ],
          ),
          onPlaceTap: (place) => selected = place,
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('Hotels first')).dy,
      lessThan(tester.getTopLeft(find.text('Places second')).dy),
    );
    await tester.ensureVisible(find.text('Gion'));
    await tester.tap(
      find.descendant(
        of: find.byType(AssistantPlaceCardView),
        matching: find.byType(InkWell),
      ),
    );
    expect(selected, same(_place));
    expect(tester.takeException(), isNull);
  });

  testWidgets('place card exposes an accessible tap action', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _app(AssistantPlaceCardView(placeCard: _place, onTap: () {})),
      );
      final node = tester.getSemantics(find.byType(AssistantPlaceCardView));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('empty sections preserve text without carousel widgets', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        AssistantMessageTile(
          message: _message(
            sections: [
              AssistantHotelCarousel(
                id: 'hotels',
                title: 'Hidden hotels',
                items: [],
              ),
              AssistantPlaceCarousel(
                id: 'places',
                title: 'Hidden places',
                items: [],
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Hidden hotels'), findsNothing);
    expect(find.text('Hidden places'), findsNothing);
    expect(find.byType(AssistantContentCarousel), findsNothing);
    expect(
      find.textContaining('Your travel suggestions.', findRichText: true),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('user text-only message has no rich sections', (tester) async {
    await tester.pumpWidget(
      _app(AssistantMessageTile(message: _message(user: true))),
    );
    expect(find.text('Your travel suggestions.'), findsOneWidget);
    expect(find.byType(AssistantContentCarousel), findsNothing);
  });
}
