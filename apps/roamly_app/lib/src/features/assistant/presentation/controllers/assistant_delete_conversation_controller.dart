import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/assistant_dependency_providers.dart';
import 'assistant_active_conversation_controller.dart';
import 'assistant_send_controller.dart';

final assistantDeleteConversationProvider =
    NotifierProvider.autoDispose<
      AssistantDeleteConversationController,
      AsyncValue<void>
    >(AssistantDeleteConversationController.new);

/// Owns deletion state; confirmation and feedback remain in the view.
final class AssistantDeleteConversationController
    extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> deleteConversation(String localId) async {
    if (state.isLoading ||
        ref.read(assistantSendControllerProvider).isSending) {
      return false;
    }
    final keepAlive = ref.keepAlive();
    state = const AsyncLoading();
    try {
      await ref
          .read(assistantRepositoryProvider)
          .deleteConversation(localId: localId);
      if (!ref.mounted) return false;
      if (ref.read(assistantActiveConversationProvider)?.localId == localId) {
        ref
            .read(assistantActiveConversationProvider.notifier)
            .startNewConversation();
        ref.read(assistantSendControllerProvider.notifier).clearFailure();
      }
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      if (ref.mounted) state = AsyncError(error, stackTrace);
      return false;
    } finally {
      keepAlive.close();
    }
  }
}
