import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_conversation.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_event.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_request.dart';
import 'package:roamly_app/src/features/assistant/domain/policies/assistant_policy.dart';
import 'package:roamly_app/src/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:roamly_app/src/features/assistant/presentation/controllers/assistant_active_conversation_controller.dart';
import 'package:roamly_app/src/features/assistant/presentation/providers/assistant_dependency_providers.dart';

const _conversationLocalId = '00000000-0000-4000-8000-000000000001';
const _otherConversationLocalId = '00000000-0000-4000-8000-000000000002';
const _remoteConversationId = '00000000-0000-4000-8000-000000000003';
const _clientMessageId = '00000000-0000-4000-8000-000000000004';

final class _FakeAssistantRepository implements AssistantRepository {
  final conversationsController =
      StreamController<List<AssistantConversation>>.broadcast();

  int watchConversationsCalls = 0;

  @override
  Stream<AssistantEvent> get events => const Stream<AssistantEvent>.empty();

  @override
  bool get isReady => false;

  @override
  Stream<bool> get readinessChanges => const Stream<bool>.empty();

  @override
  Stream<List<AssistantConversation>> watchConversations({
    int limit = AssistantPolicy.defaultConversationsLimit,
  }) {
    expect(limit, AssistantPolicy.defaultConversationsLimit);
    watchConversationsCalls++;
    return conversationsController.stream;
  }

  Future<void> close() => conversationsController.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AssistantConversation _conversation({
  String localId = _conversationLocalId,
  String? remoteId,
  String? title,
  DateTime? updatedAt,
}) {
  final createdAt = DateTime.utc(2026, 9, 23, 8);
  return AssistantConversation(
    localId: localId,
    remoteId: remoteId,
    title: title,
    createdAt: createdAt,
    updatedAt: updatedAt ?? createdAt,
  );
}

AssistantRequest _request() {
  return AssistantRequest(
    conversationLocalId: _conversationLocalId,
    clientMessageId: _clientMessageId,
    message: 'Plan a trip to Lahore',
    createdAt: DateTime.parse('2026-09-23T13:00:00+05:00'),
  );
}

void main() {
  late _FakeAssistantRepository repository;
  late ProviderContainer container;
  late ProviderSubscription<AssistantConversation?> subscription;

  setUp(() {
    repository = _FakeAssistantRepository();
    container = ProviderContainer(
      overrides: [assistantRepositoryProvider.overrideWithValue(repository)],
    );
    subscription = container.listen(
      assistantActiveConversationProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(() async {
      subscription.close();
      container.dispose();
      await repository.close();
    });
  });

  test('starts without an active conversation', () {
    expect(container.read(assistantActiveConversationProvider), isNull);
    expect(repository.watchConversationsCalls, 1);
  });

  test('selects an existing conversation and starts a new chat', () {
    final conversation = _conversation(title: 'Lahore trip');
    final controller = container.read(
      assistantActiveConversationProvider.notifier,
    );

    controller.select(conversation);
    expect(
      container.read(assistantActiveConversationProvider),
      same(conversation),
    );

    controller.startNewConversation();
    expect(container.read(assistantActiveConversationProvider), isNull);
  });

  test('activates the optimistic conversation created by a request', () {
    final request = _request();

    container
        .read(assistantActiveConversationProvider.notifier)
        .activateRequest(request);

    final conversation = container.read(assistantActiveConversationProvider);
    expect(conversation, isNotNull);
    expect(conversation!.localId, request.conversationLocalId);
    expect(conversation.remoteId, request.conversationId);
    expect(conversation.title, isNull);
    expect(conversation.createdAt, request.createdAt);
    expect(conversation.updatedAt, request.createdAt);
  });

  test('refreshes the selected conversation from persisted history', () async {
    final optimistic = _conversation();
    final persisted = _conversation(
      remoteId: _remoteConversationId,
      title: 'Lahore itinerary',
      updatedAt: DateTime.utc(2026, 9, 23, 9),
    );
    final controller = container.read(
      assistantActiveConversationProvider.notifier,
    );
    controller.select(optimistic);

    repository.conversationsController.add([persisted]);
    await container.pump();

    expect(
      container.read(assistantActiveConversationProvider),
      same(persisted),
    );
  });

  test(
    'does not replace the selection with an unrelated conversation',
    () async {
      final selected = _conversation(title: 'Selected');
      final unrelated = _conversation(
        localId: _otherConversationLocalId,
        title: 'Other',
      );
      container
          .read(assistantActiveConversationProvider.notifier)
          .select(selected);

      repository.conversationsController.add([unrelated]);
      await container.pump();

      expect(
        container.read(assistantActiveConversationProvider),
        same(selected),
      );
    },
  );
}
