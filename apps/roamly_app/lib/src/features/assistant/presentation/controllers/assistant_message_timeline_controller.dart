import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/policies/assistant_policy.dart';
import 'package:roamly_app/src/features/assistant/presentation/providers/assistant_dependency_providers.dart';
import 'package:roamly_app/src/features/assistant/presentation/providers/assistant_history_providers.dart';
import 'package:roamly_app/src/features/assistant/presentation/states/assistant_message_timeline_state.dart';

final assistantMessageTimelineProvider = NotifierProvider.autoDispose
    .family<
      AssistantMessageTimelineController,
      AssistantMessageTimelineState,
      String
    >(AssistantMessageTimelineController.new);

final class AssistantMessageTimelineController
    extends Notifier<AssistantMessageTimelineState> {
  final String _conversationLocalId;
  bool _hasLoadedOlderPage = false;

  AssistantMessageTimelineController(this._conversationLocalId);
  @override
  AssistantMessageTimelineState build() {
    final recentMessagesProvider = assistantRecentMessagesProvider(
      _conversationLocalId,
    );
    ref.listen<AsyncValue<List<AssistantMessage>>>(
      recentMessagesProvider,
      (_, next) => _handleRecentMessages(next),
    );
    return _stateFromRecentMessages(ref.read(recentMessagesProvider));
  }

  Future<void> loadOlder() async {
    final currentState = state;
    if (currentState.isInitialLoading ||
        currentState.isLoadingOlder ||
        !currentState.hasMoreOlder ||
        currentState.messages.isEmpty) {
      return;
    }
    final oldestMessage = currentState.messages.first;
    state = currentState.copyWith(isLoadingOlder: true, clearFailure: true);
    try {
      final repository = ref.read(assistantRepositoryProvider);
      final olderMessages = await repository.getMessagesBefore(
        conversationLocalId: _conversationLocalId,
        beforeId: oldestMessage.id,
        beforeCreatedAt: oldestMessage.createdAt,
        limit: AssistantPolicy.defaultMessagesLimit,
      );
      if (!ref.mounted) return;
      _hasLoadedOlderPage = true;
      if (state.messages.isEmpty) {
        state = state.copyWith(isLoadingOlder: false, hasMoreOlder: false);
        return;
      }
      state = state.copyWith(
        messages: _mergeMessages(
          current: state.messages,
          incoming: olderMessages,
        ),
        isLoadingOlder: false,
        hasMoreOlder:
            olderMessages.length == AssistantPolicy.defaultMessagesLimit,
        clearFailure: true,
      );
    } catch (error, stackTrace) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoadingOlder: false,
        failure: error,
        failureStackTrace: stackTrace,
        failureSource: AssistantTimelineFailureSource.pagination,
      );
    }
  }

  void retryRecentMessages() {
    state = state.copyWith(
      isInitialLoading: state.messages.isEmpty,
      isLoadingOlder: false,
      clearFailure: true,
    );
    ref.invalidate(assistantRecentMessagesProvider(_conversationLocalId));
  }

  void clearFailure() {
    if (!state.hasFailure) return;
    state = state.copyWith(clearFailure: true);
  }

  void _handleRecentMessages(
    AsyncValue<List<AssistantMessage>> recentMessages,
  ) {
    if (!ref.mounted) {
      return;
    }
    recentMessages.when(
      skipLoadingOnRefresh: false,
      skipLoadingOnReload: false,
      data: _applyRecentMessages,
      error: (error, stack) {
        state = state.copyWith(
          isInitialLoading: false,
          failure: error,
          failureStackTrace: stack,
          failureSource: AssistantTimelineFailureSource.recentMessages,
        );
      },
      loading: () {
        if (state.messages.isEmpty) {
          state = state.copyWith(isInitialLoading: true);
        }
      },
    );
  }

  void _applyRecentMessages(List<AssistantMessage> data) {
    if (data.isEmpty) {
      state = AssistantMessageTimelineState(
        isInitialLoading: false,
        hasMoreOlder: false,
      );
      return;
    }
    final hasMoreOlder = _hasLoadedOlderPage
        ? state.hasMoreOlder
        : data.length == AssistantPolicy.defaultMessagesLimit;
    state = state.copyWith(
      messages: _mergeMessages(current: state.messages, incoming: data),
      isInitialLoading: false,
      hasMoreOlder: hasMoreOlder,
      clearFailure: true,
    );
  }

  List<AssistantMessage> _mergeMessages({
    required List<AssistantMessage> current,
    required Iterable<AssistantMessage> incoming,
  }) {
    final messagesById = {
      for (final message in current) message.id: message,
      for (final message in incoming) message.id: message,
    };
    final messages = messagesById.values.toList(growable: false)
      ..sort(_compareMessages);
    return messages;
  }

  int _compareMessages(AssistantMessage a, AssistantMessage b) {
    final createdAtComparison = a.createdAt.compareTo(b.createdAt);
    if (createdAtComparison != 0) {
      return createdAtComparison;
    }
    return a.id.compareTo(b.id);
  }

  AssistantMessageTimelineState _stateFromRecentMessages(
    AsyncValue<List<AssistantMessage>> read,
  ) {
    return read.when(
      data: (messages) => AssistantMessageTimelineState(
        messages: messages,
        isInitialLoading: false,
        hasMoreOlder: messages.length == AssistantPolicy.defaultMessagesLimit,
      ),
      error: (error, stack) => AssistantMessageTimelineState(
        isInitialLoading: false,
        failure: error,
        failureStackTrace: stack,
        failureSource: AssistantTimelineFailureSource.recentMessages,
      ),
      loading: AssistantMessageTimelineState.new,
    );
  }
}
