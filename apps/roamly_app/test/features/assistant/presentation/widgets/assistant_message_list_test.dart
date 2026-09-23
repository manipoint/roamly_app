import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message_delivery_state.dart';
import 'package:roamly_app/src/features/assistant/presentation/states/assistant_message_timeline_state.dart';
import 'package:roamly_app/src/features/assistant/presentation/widgets/assistant_message_list.dart';
import 'package:roamly_app/src/localization/app_strings.dart';

const _conversationLocalId = '00000000-0000-4000-8000-000000000001';

String _uuid(int value) {
  return '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}';
}

AssistantMessage _message(int value) {
  final timestamp = DateTime.utc(2026, 9, 23).add(Duration(minutes: value));
  return AssistantMessage(
    id: _uuid(value + 1000),
    conversationLocalId: _conversationLocalId,
    clientMessageId: _uuid(value + 2000),
    author: AssistantMessageAuthor.user,
    content: 'Message $value',
    deliveryState: AssistantMessageDeliveryState.sent,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

Widget _app({
  required AssistantMessageTimelineState state,
  required AssistantTimelineAction onLoadOlder,
  required AssistantTimelineAction onRetryRecentMessages,
}) {
  return MaterialApp(
    home: Scaffold(
      body: AssistantMessageList(
        state: state,
        onLoadOlder: onLoadOlder,
        onRetryRecentMessages: onRetryRecentMessages,
      ),
    ),
  );
}

void main() {
  testWidgets('shows an accessible initial loading state', (tester) async {
    await tester.pumpWidget(
      _app(
        state: AssistantMessageTimelineState(),
        onLoadOlder: () async {},
        onRetryRecentMessages: () async {},
      ),
    );

    expect(
      find.bySemanticsLabel(AppStrings.assistantHistoryLoading),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows the empty conversation status', (tester) async {
    await tester.pumpWidget(
      _app(
        state: AssistantMessageTimelineState(isInitialLoading: false),
        onLoadOlder: () async {},
        onRetryRecentMessages: () async {},
      ),
    );

    expect(find.text(AppStrings.assistantNoMessages), findsOneWidget);
    expect(
      find.byKey(const ValueKey('assistant-timeline-status')),
      findsOneWidget,
    );
  });

  testWidgets('routes an initial history error to recent-message retry', (
    tester,
  ) async {
    var historyRetryCalls = 0;
    var loadOlderCalls = 0;
    await tester.pumpWidget(
      _app(
        state: AssistantMessageTimelineState(
          isInitialLoading: false,
          failure: StateError('history failed'),
          failureSource: AssistantTimelineFailureSource.recentMessages,
        ),
        onLoadOlder: () async => loadOlderCalls++,
        onRetryRecentMessages: () async => historyRetryCalls++,
      ),
    );

    await tester.tap(find.text(AppStrings.tryAgain));
    await tester.pump();

    expect(historyRetryCalls, 1);
    expect(loadOlderCalls, 0);
    expect(find.text(AppStrings.assistantHistoryLoadFailed), findsOneWidget);
  });

  testWidgets('shows chronological messages with the newest at the bottom', (
    tester,
  ) async {
    final first = _message(1);
    final second = _message(2);
    await tester.pumpWidget(
      _app(
        state: AssistantMessageTimelineState(
          messages: [first, second],
          isInitialLoading: false,
        ),
        onLoadOlder: () async {},
        onRetryRecentMessages: () async {},
      ),
    );

    expect(
      find.byKey(const ValueKey('assistant-message-list')),
      findsOneWidget,
    );
    expect(
      tester.getCenter(find.text(second.content)).dy,
      greaterThan(tester.getCenter(find.text(first.content)).dy),
    );
  });

  testWidgets('routes a live history error to recent-message retry', (
    tester,
  ) async {
    var historyRetryCalls = 0;
    var loadOlderCalls = 0;
    await tester.pumpWidget(
      _app(
        state: AssistantMessageTimelineState(
          messages: [_message(1)],
          isInitialLoading: false,
          failure: StateError('refresh failed'),
          failureSource: AssistantTimelineFailureSource.recentMessages,
        ),
        onLoadOlder: () async => loadOlderCalls++,
        onRetryRecentMessages: () async => historyRetryCalls++,
      ),
    );

    await tester.tap(find.text(AppStrings.tryAgain));
    await tester.pump();

    expect(historyRetryCalls, 1);
    expect(loadOlderCalls, 0);
  });

  testWidgets('guards repeated pagination retry taps', (tester) async {
    final completer = Completer<void>();
    var loadOlderCalls = 0;
    await tester.pumpWidget(
      _app(
        state: AssistantMessageTimelineState(
          messages: [_message(1)],
          isInitialLoading: false,
          hasMoreOlder: true,
          failure: StateError('pagination failed'),
          failureSource: AssistantTimelineFailureSource.pagination,
        ),
        onLoadOlder: () {
          loadOlderCalls++;
          return completer.future;
        },
        onRetryRecentMessages: () async {},
      ),
    );

    final retry = find.text(AppStrings.tryAgain);
    await tester.tap(retry);
    await tester.tap(retry);
    await tester.pump();

    expect(loadOlderCalls, 1);

    completer.complete();
    await tester.pumpAndSettle();
  });
}
