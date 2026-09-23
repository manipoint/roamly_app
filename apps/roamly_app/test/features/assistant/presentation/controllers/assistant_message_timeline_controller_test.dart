import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_event.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message_delivery_state.dart';
import 'package:roamly_app/src/features/assistant/domain/policies/assistant_policy.dart';
import 'package:roamly_app/src/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:roamly_app/src/features/assistant/presentation/controllers/assistant_message_timeline_controller.dart';
import 'package:roamly_app/src/features/assistant/presentation/providers/assistant_dependency_providers.dart';
import 'package:roamly_app/src/features/assistant/presentation/states/assistant_message_timeline_state.dart';

const _conversationLocalId = '00000000-0000-4000-8000-000000000001';

String _uuid(int value) {
  return '00000000-0000-4000-8000-${value.toString().padLeft(12, '0')}';
}

AssistantMessage _message(int value, {DateTime? createdAt, String? content}) {
  final timestamp =
      createdAt ?? DateTime.utc(2026, 1, 1).add(Duration(seconds: value));

  return AssistantMessage(
    id: _uuid(value + 1000),
    conversationLocalId: _conversationLocalId,
    clientMessageId: _uuid(value + 2000),
    author: AssistantMessageAuthor.user,
    content: content ?? 'Message $value',
    deliveryState: AssistantMessageDeliveryState.sent,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

final class _FakeAssistantRepository implements AssistantRepository {
  final messagesController =
      StreamController<List<AssistantMessage>>.broadcast();
  final paginationCursors = <({String id, DateTime createdAt, int limit})>[];

  List<AssistantMessage> olderMessages = const [];
  Completer<List<AssistantMessage>>? paginationCompleter;
  Object? paginationFailure;
  int watchMessagesCalls = 0;

  @override
  Stream<AssistantEvent> get events => const Stream<AssistantEvent>.empty();

  @override
  bool get isReady => false;

  @override
  Stream<bool> get readinessChanges => const Stream<bool>.empty();

  @override
  Stream<List<AssistantMessage>> watchMessages({
    required String conversationLocalId,
    int limit = AssistantPolicy.defaultMessagesLimit,
  }) {
    expect(conversationLocalId, _conversationLocalId);
    expect(limit, AssistantPolicy.defaultMessagesLimit);
    watchMessagesCalls++;
    return messagesController.stream;
  }

  @override
  Future<List<AssistantMessage>> getMessagesBefore({
    required String conversationLocalId,
    required String beforeId,
    required DateTime beforeCreatedAt,
    int limit = AssistantPolicy.defaultMessagesLimit,
  }) async {
    expect(conversationLocalId, _conversationLocalId);
    paginationCursors.add((
      id: beforeId,
      createdAt: beforeCreatedAt,
      limit: limit,
    ));

    final failure = paginationFailure;
    if (failure != null) throw failure;

    return paginationCompleter?.future ?? olderMessages;
  }

  Future<void> close() => messagesController.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _eventually(bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 1));
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition timed out.');
    }
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _FakeAssistantRepository repository;
  late ProviderContainer container;
  late ProviderSubscription<AssistantMessageTimelineState> subscription;

  final provider = assistantMessageTimelineProvider(_conversationLocalId);

  setUp(() {
    repository = _FakeAssistantRepository();
    container = ProviderContainer(
      overrides: [assistantRepositoryProvider.overrideWithValue(repository)],
    );
    subscription = container.listen(provider, (_, _) {}, fireImmediately: true);
    addTearDown(() async {
      subscription.close();
      container.dispose();
      await repository.close();
    });
  });

  test(
    'starts loading and exposes chronologically ordered live messages',
    () async {
      expect(container.read(provider).isInitialLoading, isTrue);

      final later = _message(2);
      final earlier = _message(1);
      repository.messagesController.add([later, earlier]);
      await container.pump();

      final state = container.read(provider);
      expect(state.isInitialLoading, isFalse);
      expect(state.messages.map((message) => message.id), [
        earlier.id,
        later.id,
      ]);
      expect(state.hasMoreOlder, isFalse);
    },
  );

  test(
    'loads an older page using the oldest cursor and stops at the end',
    () async {
      final recentMessages = [
        for (
          var index = 101;
          index < 101 + AssistantPolicy.defaultMessagesLimit;
          index++
        )
          _message(index),
      ];
      repository.messagesController.add(recentMessages);
      await container.pump();
      expect(container.read(provider).hasMoreOlder, isTrue);

      final olderMessages = [_message(1), _message(2)];
      repository.olderMessages = olderMessages;

      await container.read(provider.notifier).loadOlder();

      final state = container.read(provider);
      expect(repository.paginationCursors, hasLength(1));
      expect(repository.paginationCursors.single.id, recentMessages.first.id);
      expect(
        repository.paginationCursors.single.createdAt,
        recentMessages.first.createdAt,
      );
      expect(
        repository.paginationCursors.single.limit,
        AssistantPolicy.defaultMessagesLimit,
      );
      expect(state.isLoadingOlder, isFalse);
      expect(state.hasMoreOlder, isFalse);
      expect(state.messages.take(2), olderMessages);

      await container.read(provider.notifier).loadOlder();
      expect(repository.paginationCursors, hasLength(1));
    },
  );

  test('deduplicates concurrent pagination requests', () async {
    final recentMessages = [
      for (
        var index = 101;
        index < 101 + AssistantPolicy.defaultMessagesLimit;
        index++
      )
        _message(index),
    ];
    repository.messagesController.add(recentMessages);
    await container.pump();

    repository.paginationCompleter = Completer<List<AssistantMessage>>();
    final controller = container.read(provider.notifier);
    final first = controller.loadOlder();
    final second = controller.loadOlder();

    expect(container.read(provider).isLoadingOlder, isTrue);
    expect(repository.paginationCursors, hasLength(1));

    repository.paginationCompleter!.complete(const []);
    await Future.wait([first, second]);

    expect(container.read(provider).isLoadingOlder, isFalse);
    expect(container.read(provider).hasMoreOlder, isFalse);
  });

  test('preserves messages and exposes a pagination failure', () async {
    final recentMessages = [
      for (
        var index = 101;
        index < 101 + AssistantPolicy.defaultMessagesLimit;
        index++
      )
        _message(index),
    ];
    repository.messagesController.add(recentMessages);
    await container.pump();

    final failure = StateError('pagination failed');
    repository.paginationFailure = failure;
    await container.read(provider.notifier).loadOlder();

    final failedState = container.read(provider);
    expect(failedState.messages, recentMessages);
    expect(failedState.isLoadingOlder, isFalse);
    expect(failedState.failure, same(failure));

    container.read(provider.notifier).clearFailure();
    expect(container.read(provider).failure, isNull);
  });

  test('retry clears a recent-stream failure and resubscribes', () async {
    final failure = StateError('history failed');
    repository.messagesController.addError(failure, StackTrace.current);
    await container.pump();

    expect(container.read(provider).failure, same(failure));

    container.read(provider.notifier).retryRecentMessages();

    final retryingState = container.read(provider);
    expect(retryingState.failure, isNull);
    expect(retryingState.isInitialLoading, isTrue);
    expect(retryingState.isLoadingOlder, isFalse);
    await _eventually(() => repository.watchMessagesCalls == 2);

    final message = _message(1);
    repository.messagesController.add([message]);
    await container.pump();

    final recoveredState = container.read(provider);
    expect(recoveredState.isInitialLoading, isFalse);
    expect(recoveredState.failure, isNull);
    expect(recoveredState.messages, [message]);
  });

  test(
    'live updates replace duplicates and retain displaced messages',
    () async {
      final first = _message(1);
      final second = _message(2);
      repository.messagesController.add([second, first]);
      await container.pump();

      final updatedFirst = _message(1, content: 'Updated message');
      final third = _message(3);
      repository.messagesController.add([third, updatedFirst]);
      await container.pump();

      final messages = container.read(provider).messages;
      expect(messages.map((message) => message.id), [
        first.id,
        second.id,
        third.id,
      ]);
      expect(messages.first.content, 'Updated message');
    },
  );

  test('state prevents external message-list mutation', () async {
    repository.messagesController.add([_message(1)]);
    await container.pump();

    expect(
      () => container.read(provider).messages.add(_message(2)),
      throwsUnsupportedError,
    );
  });
}
