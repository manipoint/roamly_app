import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_conversation.dart';
import 'package:roamly_app/src/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:roamly_app/src/features/assistant/presentation/controllers/assistant_active_conversation_controller.dart';
import 'package:roamly_app/src/features/assistant/presentation/pages/assistant_page.dart';
import 'package:roamly_app/src/features/assistant/presentation/providers/assistant_connection_provider.dart';
import 'package:roamly_app/src/features/assistant/presentation/providers/assistant_dependency_providers.dart';
import 'package:roamly_app/src/features/assistant/presentation/providers/assistant_history_providers.dart';
import 'package:roamly_app/src/localization/app_strings.dart';

final class _Repository implements AssistantRepository {
  final deleted = <String>[];
  bool fail = false;
  @override
  Future<void> deleteConversation({required String localId}) async {
    if (fail) throw StateError('delete failed');
    deleted.add(localId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final action in ['new', 'cancel', 'delete', 'failure', 'history']) {
    testWidgets('conversation action $action', (tester) async {
      final repository = _Repository()..fail = action == 'failure';
      final conversation = AssistantConversation(
        localId: '10000000-0000-4000-8000-000000000001',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final older = AssistantConversation(
        localId: '10000000-0000-4000-8000-000000000002',
        title: 'Japan trip',
        createdAt: DateTime.utc(2025),
        updatedAt: DateTime.utc(2025),
      );
      final container = ProviderContainer(
        overrides: [
          assistantRepositoryProvider.overrideWithValue(repository),
          assistantRecentMessagesProvider(
            older.localId,
          ).overrideWith((ref) => Stream.value([])),
          assistantReadinessProvider.overrideWith((ref) => Stream.value(true)),
          assistantConversationsProvider.overrideWith(
            (ref) => Stream.value([conversation, older]),
          ),
          assistantRecentMessagesProvider(
            conversation.localId,
          ).overrideWith((ref) => Stream.value([])),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: AssistantPage())),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        container.read(assistantActiveConversationProvider)?.localId,
        conversation.localId,
      );
      await tester.tap(find.byTooltip(AppStrings.assistantConversationActions));
      await tester.pumpAndSettle();
      if (action == 'history') {
        expect(find.text('Japan trip'), findsOneWidget);
        await tester.tap(
          find.ancestor(
            of: find.text('Japan trip'),
            matching: find.byType(CheckedPopupMenuItem<String>),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          container.read(assistantActiveConversationProvider)?.localId,
          older.localId,
        );
        expect(repository.deleted, isEmpty);
        expect(tester.takeException(), isNull);
        return;
      }
      await tester.tap(
        find.text(
          action == 'new'
              ? AppStrings.assistantNewConversation
              : AppStrings.assistantDeleteConversation,
        ),
      );
      await tester.pumpAndSettle();
      if (action != 'new') {
        expect(
          find.text(AppStrings.assistantDeleteConfirmation),
          findsOneWidget,
        );
        await tester.tap(
          find.text(
            action == 'cancel'
                ? AppStrings.assistantCancel
                : AppStrings.assistantDelete,
          ),
        );
        await tester.pumpAndSettle();
      }
      expect(
        repository.deleted,
        action == 'delete' ? [conversation.localId] : isEmpty,
      );
      if (action == 'new' || action == 'delete') {
        expect(container.read(assistantActiveConversationProvider), isNull);
      } else {
        expect(
          container.read(assistantActiveConversationProvider)?.localId,
          conversation.localId,
        );
      }
      if (action == 'failure') {
        expect(find.text(AppStrings.assistantDeleteFailed), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
