import '../controllers/assistant_delete_conversation_controller.dart';
import '../providers/assistant_history_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/features/assistant/presentation/controllers/assistant_active_conversation_controller.dart';
import 'package:roamly_app/src/features/assistant/presentation/controllers/assistant_message_timeline_controller.dart';
import 'package:roamly_app/src/features/assistant/presentation/controllers/assistant_send_controller.dart';
import 'package:roamly_app/src/features/assistant/presentation/providers/assistant_connection_provider.dart';
import 'package:roamly_app/src/features/assistant/presentation/widgets/assistant_message_composer.dart';
import 'package:roamly_app/src/features/assistant/presentation/widgets/assistant_message_list.dart';
import 'package:roamly_app/src/features/assistant/presentation/widgets/assistant_timeline_status_view.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

final class AssistantPage extends ConsumerStatefulWidget {
  const AssistantPage({super.key});

  @override
  ConsumerState<AssistantPage> createState() => _AssistantPageState();
}

final class _AssistantPageState extends ConsumerState<AssistantPage> {
  int _draftGeneration = 0;

  void _startNew() {
    ref
        .read(assistantActiveConversationProvider.notifier)
        .startNewConversation();
    ref.read(assistantSendControllerProvider.notifier).clearFailure();
    setState(() => _draftGeneration++);
  }

  Future<void> _confirmDeleteConversation(String localId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.assistantDeleteConversation),
        content: const Text(AppStrings.assistantDeleteConfirmation),
        actions: [
          RoamlyButton.ghost(
            onPressed: () => Navigator.pop(context, false),
            label: AppStrings.assistantCancel,
          ),
          RoamlyButton.ghost(
            onPressed: () => Navigator.pop(context, true),
            label: AppStrings.assistantDelete,
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final deleted = await ref
        .read(assistantDeleteConversationProvider.notifier)
        .deleteConversation(localId);
    if (!mounted) return;
    if (deleted) {
      setState(() => _draftGeneration++);
    } else if (ref.read(assistantDeleteConversationProvider).hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.assistantDeleteFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(assistantReadinessProvider);

    final activeConversation = ref.watch(assistantActiveConversationProvider);
    final sendState = ref.watch(assistantSendControllerProvider);
    final deletion = ref.watch(assistantDeleteConversationProvider);
    final history = ref.watch(assistantConversationsProvider);
    final conversations = history.asData?.value ?? const [];

    return RoamlyScaffold(
      safeAreaTop: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: PopupMenuButton<String>(
        icon: const Icon(Icons.sort),
        tooltip: AppStrings.assistantConversationActions,
        enabled: !sendState.isSending && !deletion.isLoading,
        onSelected: (action) {
          if (action == 'new') _startNew();
          if (action == 'retry-history') {
            ref.invalidate(assistantConversationsProvider);
          }
          for (final conversation in conversations) {
            if (action == 'conversation:${conversation.localId}') {
              if (activeConversation?.localId != conversation.localId) {
                ref
                    .read(assistantActiveConversationProvider.notifier)
                    .select(conversation);
                ref
                    .read(assistantSendControllerProvider.notifier)
                    .clearFailure();
                setState(() => _draftGeneration++);
              }
              break;
            }
          }
          if (action == 'delete' && activeConversation != null) {
            _confirmDeleteConversation(activeConversation.localId);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'new',
            child: Text(AppStrings.assistantNewConversation),
          ),
          if (activeConversation != null)
            const PopupMenuItem(
              value: 'delete',
              child: Text(AppStrings.assistantDeleteConversation),
            ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            enabled: false,
            child: Text(AppStrings.assistantRecentConversations),
          ),
          if (history.isLoading)
            const PopupMenuItem<String>(
              enabled: false,
              child: Text(AppStrings.assistantHistoryLoading),
            ),
          if (history.hasError)
            const PopupMenuItem(
              value: 'retry-history',
              child: Text(AppStrings.assistantHistoryRetry),
            ),
          if (history.hasValue && conversations.isEmpty)
            const PopupMenuItem<String>(
              enabled: false,
              child: Text(AppStrings.assistantHistoryEmpty),
            ),
          for (final conversation in conversations)
            CheckedPopupMenuItem<String>(
              value: 'conversation:${conversation.localId}',
              checked: activeConversation?.localId == conversation.localId,
              child: Text(
                conversation.title ??
                    '${AppStrings.assistantUntitledConversation} · ${MaterialLocalizations.of(context).formatShortDate(conversation.createdAt.toLocal())}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      body: Column(
        key: const ValueKey<String>('assistant-page'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: activeConversation == null
                ? const AssistantTimelineStatusView(
                    icon: Icons.auto_awesome_rounded,
                    message: AppStrings.assistantNoMessages,
                  )
                : _AssistantConversationTimeline(
                    conversationLocalId: activeConversation.localId,
                  ),
          ),
          AssistantMessageComposer(
            key: ValueKey(_draftGeneration),
            enabled: !deletion.isLoading,
            isSending: sendState.isSending,
            errorText: sendState.hasFailure
                ? AppStrings.assistantSendFailed
                : null,
            onSubmit: (message) async {
              final request = await ref
                  .read(assistantSendControllerProvider.notifier)
                  .sendMessage(message: message);

              return request != null;
            },
          ),
        ],
      ),
    );
  }
}

final class _AssistantConversationTimeline extends ConsumerWidget {
  const _AssistantConversationTimeline({required this.conversationLocalId});

  final String conversationLocalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineProvider = assistantMessageTimelineProvider(
      conversationLocalId,
    );
    final timelineState = ref.watch(timelineProvider);

    return Padding(
      padding: EdgeInsets.only(top: RoamlySpacing.space48),
      child: AssistantMessageList(
        state: timelineState,
        onLoadOlder: () {
          return ref.read(timelineProvider.notifier).loadOlder();
        },
        onRetryRecentMessages: () async {
          ref.read(timelineProvider.notifier).retryRecentMessages();
        },
      ),
    );
  }
}
