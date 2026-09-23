import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_conversation.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_request.dart';
import 'package:roamly_app/src/features/assistant/presentation/providers/assistant_history_providers.dart';

final assistantActiveConversationProvider =
    NotifierProvider.autoDispose<
      AssistantActiveConversationController,
      AssistantConversation?
    >(AssistantActiveConversationController.new);

final class AssistantActiveConversationController
    extends Notifier<AssistantConversation?> {
  bool _hasResolvedInitialSelection = false;
  @override
  AssistantConversation? build() {
    ref.listen(
      assistantConversationsProvider,
      (_, next) => next.whenData(_handleConversations),
    );
    return null;
  }

  void select(AssistantConversation conversation) {
    _hasResolvedInitialSelection = true;
    if (state == conversation) {
      return;
    }
    state = conversation;
  }

  void startNewConversation() {
    _hasResolvedInitialSelection = true;
    if (state == null) return;

    state = null;
  }

  /// Activates the local conversation created by the first successful request.
  ///
  /// The conversations stream will later replace this optimistic value with
  /// the persisted conversation containing its title and remote ID.
  void activateRequest(AssistantRequest request) {
    _hasResolvedInitialSelection = true;
    if (state?.localId == request.conversationLocalId) {
      return;
    }
    state = AssistantConversation(
      localId: request.conversationLocalId,
      remoteId: request.conversationId,
      createdAt: request.createdAt,
      updatedAt: request.createdAt,
    );
  }

  void _handleConversations(List<AssistantConversation> value) {
    if (!_hasResolvedInitialSelection) {
      _hasResolvedInitialSelection = true;

      if (value.isNotEmpty) {
        state = value.first;
      }
      return;
    }
    final selectedConversation = state;
    if (selectedConversation == null) {
      return;
    }
    for (final conversation in value) {
      if (conversation.localId != selectedConversation.localId) {
        continue;
      }
      if (conversation != selectedConversation) {
        state = conversation;
      }
      return;
    }
  }
}
