import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/application/factories/assistant_request_factory.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_conversation.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_event.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_request.dart';
import 'package:roamly_app/src/features/assistant/domain/policies/assistant_policy.dart';
import 'package:roamly_app/src/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:roamly_app/src/features/assistant/presentation/controllers/assistant_active_conversation_controller.dart';
import 'package:roamly_app/src/features/assistant/presentation/controllers/assistant_send_controller.dart';
import 'package:roamly_app/src/features/assistant/presentation/providers/assistant_dependency_providers.dart';
import 'package:roamly_app/src/features/assistant/presentation/providers/assistant_request_factory_provider.dart';
import 'package:roamly_app/src/features/assistant/presentation/states/assistant_send_satate.dart';

final class _FakeAssistantRepository implements AssistantRepository {
  final requests = <AssistantRequest>[];
  Completer<void>? sendCompleter;
  Object? sendFailure;

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
    return const Stream<List<AssistantConversation>>.empty();
  }

  @override
  Future<void> sendRequest(AssistantRequest request) async {
    requests.add(request);
    final failure = sendFailure;
    if (failure != null) throw failure;
    await sendCompleter?.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const conversationLocalId = '00000000-0000-4000-8000-000000000001';
  const clientMessageId = '00000000-0000-4000-8000-000000000002';
  const remoteConversationId = '00000000-0000-4000-8000-000000000003';
  const tripId = '00000000-0000-4000-8000-000000000004';
  const secondClientMessageId = '00000000-0000-4000-8000-000000000005';
  final timestamp = DateTime.parse('2026-09-22T13:00:00+05:00');

  late _FakeAssistantRepository repository;
  late ProviderContainer container;
  late ProviderSubscription<AssistantSendState> subscription;
  late ProviderSubscription<AssistantConversation?> activeSubscription;

  setUp(() {
    repository = _FakeAssistantRepository();
    final ids = <String>[
      conversationLocalId,
      clientMessageId,
      secondClientMessageId,
    ];
    var idIndex = 0;
    container = ProviderContainer(
      overrides: [
        assistantRepositoryProvider.overrideWithValue(repository),
        assistantRequestFactoryProvider.overrideWithValue(
          AssistantRequestFactory(
            idGenerator: () => ids[idIndex++],
            clock: () => timestamp,
          ),
        ),
      ],
    );
    subscription = container.listen(
      assistantSendControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    activeSubscription = container.listen(
      assistantActiveConversationProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(() {
      subscription.close();
      activeSubscription.close();
      container.dispose();
    });
  });

  test('starts idle', () {
    final state = container.read(assistantSendControllerProvider);

    expect(state.status, AssistantSendStatus.idle);
    expect(state.isSending, isFalse);
    expect(state.hasFailure, isFalse);
    expect(state.failure, isNull);
  });

  test('creates and submits a request for a new conversation', () async {
    final request = await container
        .read(assistantSendControllerProvider.notifier)
        .sendMessage(
          message: '  Plan Lahore  ',
          locale: '  en-PK  ',
          tripId: tripId,
        );

    expect(request, isNotNull);
    expect(repository.requests, hasLength(1));
    expect(repository.requests.single, same(request));
    expect(request!.conversationLocalId, conversationLocalId);
    expect(request.clientMessageId, clientMessageId);
    expect(request.message, 'Plan Lahore');
    expect(request.locale, 'en-PK');
    expect(request.tripId, tripId);
    expect(request.createdAt, DateTime.utc(2026, 9, 22, 8));
    expect(
      container.read(assistantActiveConversationProvider)?.localId,
      conversationLocalId,
    );
    expect(
      container.read(assistantSendControllerProvider).status,
      AssistantSendStatus.idle,
    );
  });

  test('reuses the active conversation for the next request', () async {
    final controller = container.read(assistantSendControllerProvider.notifier);

    final first = await controller.sendMessage(message: 'Plan Lahore');
    final second = await controller.sendMessage(message: 'Add food places');

    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(second!.conversationLocalId, first!.conversationLocalId);
    expect(second.clientMessageId, secondClientMessageId);
    expect(repository.requests, [first, second]);
  });

  test('uses both identifiers from an existing conversation', () async {
    final conversation = AssistantConversation(
      localId: conversationLocalId,
      remoteId: remoteConversationId,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    final request = await container
        .read(assistantSendControllerProvider.notifier)
        .sendMessage(message: 'Continue planning', conversation: conversation);

    expect(request, isNotNull);
    expect(request!.conversationLocalId, conversationLocalId);
    expect(request.conversationId, remoteConversationId);
  });

  test('ignores a second submission while one is in flight', () async {
    repository.sendCompleter = Completer<void>();
    final controller = container.read(assistantSendControllerProvider.notifier);

    final first = controller.sendMessage(message: 'First request');
    final second = await controller.sendMessage(message: 'Duplicate tap');

    expect(second, isNull);
    expect(repository.requests, hasLength(1));
    expect(container.read(assistantSendControllerProvider).isSending, isTrue);

    repository.sendCompleter!.complete();
    expect(await first, isNotNull);
    expect(
      container.read(assistantSendControllerProvider).status,
      AssistantSendStatus.idle,
    );
  });

  test('exposes validation failure without calling the repository', () async {
    final result = await container
        .read(assistantSendControllerProvider.notifier)
        .sendMessage(message: '   ');

    final state = container.read(assistantSendControllerProvider);
    expect(result, isNull);
    expect(repository.requests, isEmpty);
    expect(state.status, AssistantSendStatus.failed);
    expect(state.failure, isA<ArgumentError>());
    expect(container.read(assistantActiveConversationProvider), isNull);
  });

  test('exposes repository failure and can clear it', () async {
    final failure = StateError('send failed');
    repository.sendFailure = failure;

    final result = await container
        .read(assistantSendControllerProvider.notifier)
        .sendMessage(message: 'Plan Lahore');

    expect(result, isNull);
    expect(
      container.read(assistantSendControllerProvider).failure,
      same(failure),
    );
    expect(container.read(assistantActiveConversationProvider), isNull);

    container.read(assistantSendControllerProvider.notifier).clearFailure();

    final state = container.read(assistantSendControllerProvider);
    expect(state.status, AssistantSendStatus.idle);
    expect(state.failure, isNull);
  });
}
