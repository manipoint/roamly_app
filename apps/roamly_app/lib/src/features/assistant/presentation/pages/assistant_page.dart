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

final class AssistantPage extends ConsumerWidget {
  const AssistantPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(assistantReadinessProvider);

    final activeConversation = ref.watch(assistantActiveConversationProvider);
    final sendState = ref.watch(assistantSendControllerProvider);

    return SafeArea(
      bottom: false,
      left: false,
      right: false,
      child: Column(
        key: const ValueKey<String>('assistant-page'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              RoamlySpacing.space16,
              RoamlySpacing.space16,
              RoamlySpacing.space16,
              RoamlySpacing.space12,
            ),
            child: Text(
              AppStrings.assistantTab,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
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

    return AssistantMessageList(
      state: timelineState,
      onLoadOlder: () {
        return ref.read(timelineProvider.notifier).loadOlder();
      },
      onRetryRecentMessages: () async {
        ref.read(timelineProvider.notifier).retryRecentMessages();
      },
    );
  }
}
