import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_event.dart';
import 'package:roamly_app/src/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:roamly_app/src/features/assistant/presentation/providers/assistant_connection_provider.dart';
import 'package:roamly_app/src/features/assistant/presentation/providers/assistant_dependency_providers.dart';

final class _FakeAssistantRepository implements AssistantRepository {
  final StreamController<bool> readinessController =
      StreamController<bool>.broadcast();

  bool ready = false;
  Object? connectError;
  int connectCalls = 0;
  int disconnectCalls = 0;

  @override
  bool get isReady => ready;

  @override
  Stream<bool> get readinessChanges => readinessController.stream;

  @override
  Stream<AssistantEvent> get events => const Stream<AssistantEvent>.empty();

  @override
  void connect() {
    connectCalls++;
    final error = connectError;
    if (error != null) throw error;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
  }

  Future<void> close() => readinessController.close();

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

  setUp(() {
    repository = _FakeAssistantRepository();
    container = ProviderContainer(
      overrides: [assistantRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(() async {
      container.dispose();
      await repository.close();
    });
  });

  test('does not connect before the provider is watched', () {
    expect(repository.connectCalls, 0);
  });

  test('connects once and exposes the initial readiness', () async {
    repository.ready = true;
    final subscription = container.listen(
      assistantReadinessProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final readiness = await container.read(assistantReadinessProvider.future);

    expect(readiness, isTrue);
    expect(repository.connectCalls, 1);
  });

  test('forwards readiness changes without duplicate values', () async {
    final observed = <bool>[];
    final subscription = container.listen(assistantReadinessProvider, (
      _,
      next,
    ) {
      final value = next.value;
      if (value != null) observed.add(value);
    }, fireImmediately: true);
    addTearDown(subscription.close);

    await container.read(assistantReadinessProvider.future);
    repository.readinessController
      ..add(true)
      ..add(true)
      ..add(false);
    await container.pump();

    expect(observed, <bool>[false, true, false]);
  });

  test('forwards a synchronous connection failure', () async {
    final failure = StateError('connection failed');
    repository.connectError = failure;
    final subscription = container.listen(
      assistantReadinessProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container.pump();

    expect(container.read(assistantReadinessProvider).error, same(failure));
  });

  test('disconnects when the final listener is removed', () async {
    final subscription = container.listen(
      assistantReadinessProvider,
      (_, _) {},
      fireImmediately: true,
    );
    await container.read(assistantReadinessProvider.future);

    subscription.close();
    await _eventually(() => repository.disconnectCalls == 1);

    expect(repository.disconnectCalls, 1);
  });
}
