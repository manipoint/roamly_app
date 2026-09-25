import 'dart:async';

import 'package:flutter/material.dart';
import 'package:roamly_app/src/features/assistant/presentation/states/assistant_message_timeline_state.dart';
import 'package:roamly_app/src/features/assistant/presentation/widgets/assistant_inline_error_banner.dart';
import 'package:roamly_app/src/features/assistant/presentation/widgets/assistant_message_bubble.dart';
import 'package:roamly_app/src/features/assistant/presentation/widgets/assistant_thinking_indicator.dart';
import 'package:roamly_app/src/features/assistant/presentation/widgets/assistant_timeline_status_view.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

typedef AssistantTimelineAction = Future<void> Function();

final class AssistantMessageList extends StatefulWidget {
  const AssistantMessageList({
    super.key,
    required this.state,
    required this.onLoadOlder,
    required this.onRetryRecentMessages,
  });

  final AssistantMessageTimelineState state;
  final AssistantTimelineAction onLoadOlder;
  final AssistantTimelineAction onRetryRecentMessages;

  @override
  State<AssistantMessageList> createState() => _AssistantMessageListState();
}

final class _AssistantMessageListState extends State<AssistantMessageList> {
  static const double _paginationThreshold = 240;

  late final ScrollController _scrollController;

  bool _isRequestingOlder = false;

  bool get _hasInitialFailure {
    return widget.state.messages.isEmpty &&
        widget.state.hasFailure &&
        widget.state.failureSource != AssistantTimelineFailureSource.pagination;
  }

  bool get _hasRecentMessagesFailure {
    return widget.state.hasFailure &&
        widget.state.failureSource != AssistantTimelineFailureSource.pagination;
  }

  bool get _hasPaginationFailure {
    return widget.state.hasFailure &&
        widget.state.failureSource == AssistantTimelineFailureSource.pagination;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _isRequestingOlder ||
        widget.state.isInitialLoading ||
        widget.state.isLoadingOlder ||
        widget.state.hasFailure ||
        !widget.state.hasMoreOlder) {
      return;
    }

    final position = _scrollController.position;

    // The list is reversed. Its maximum extent represents the visual top.
    if (position.maxScrollExtent - position.pixels <= _paginationThreshold) {
      unawaited(_loadOlder());
    }
  }

  Future<void> _loadOlder() async {
    if (_isRequestingOlder ||
        widget.state.isLoadingOlder ||
        !widget.state.hasMoreOlder) {
      return;
    }

    _isRequestingOlder = true;

    try {
      await widget.onLoadOlder();
    } finally {
      _isRequestingOlder = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.isInitialLoading && widget.state.messages.isEmpty) {
      return const _AssistantTimelineLoading();
    }
    if (_hasInitialFailure) {
      return AssistantTimelineStatusView(
        icon: Icons.error_outline_rounded,
        iconColor: Theme.of(context).colorScheme.error,
        message: AppStrings.assistantHistoryLoadFailed,
        actionLabel: AppStrings.tryAgain,
        onAction: widget.onRetryRecentMessages,
      );
    }
    if (widget.state.messages.isEmpty) {
      return const AssistantTimelineStatusView(
        icon: Icons.auto_awesome_rounded,
        message: AppStrings.assistantNoMessages,
      );
    }
    final showThinkingIndicator = widget.state.isAwaitingAssistantResponse;

    final thinkingItemCount = showThinkingIndicator ? 1 : 0;

    return Column(
      children: [
        if (_hasRecentMessagesFailure)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              RoamlySpacing.space16,
              RoamlySpacing.space8,
              RoamlySpacing.space16,
              0,
            ),
            child: AssistantInlineErrorBanner(
              message: AppStrings.assistantHistoryLoadFailed,
              onRetry: widget.onRetryRecentMessages,
            ),
          ),
        Expanded(
          child: ListView.builder(
            key: const ValueKey('assistant-message-list'),
            controller: _scrollController,
            reverse: true,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(
              horizontal: RoamlySpacing.space16,
              vertical: RoamlySpacing.space12,
            ),

            // Messages + optional thinking item + pagination status item.
            itemCount: widget.state.messages.length + thinkingItemCount + 1,

            itemBuilder: (context, index) {
              // Because the list is reversed, index 0 appears at the bottom.
              if (showThinkingIndicator && index == 0) {
                return const Padding(
                  key: ValueKey('assistant-thinking-indicator'),
                  padding: EdgeInsets.only(bottom: RoamlySpacing.space12),
                  child: AssistantThinkingIndicator(),
                );
              }

              // Remove the optional thinking item from index calculations.
              final adjustedIndex = index - thinkingItemCount;

              // The final item represents pagination state at the visual top.
              if (adjustedIndex == widget.state.messages.length) {
                if (widget.state.isLoadingOlder) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: RoamlySpacing.space12,
                    ),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  );
                }

                if (_hasPaginationFailure) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: RoamlySpacing.space12,
                    ),
                    child: AssistantInlineErrorBanner(
                      message: AppStrings.assistantOlderMessagesLoadFailed,
                      onRetry: _loadOlder,
                    ),
                  );
                }

                return const SizedBox(height: RoamlySpacing.space8);
              }

              final messageIndex =
                  widget.state.messages.length - 1 - adjustedIndex;

              final message = widget.state.messages[messageIndex];

              return Padding(
                key: ValueKey<String>('assistant-message-${message.id}'),
                padding: const EdgeInsets.only(bottom: RoamlySpacing.space12),
                child: AssistantMessageBubble(message: message),
              );
            },
          ),
        ),
      ],
    );
  }
}

final class _AssistantTimelineLoading extends StatelessWidget {
  const _AssistantTimelineLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        container: true,
        liveRegion: true,
        label: AppStrings.assistantHistoryLoading,
        child: const ExcludeSemantics(
          child: CircularProgressIndicator.adaptive(),
        ),
      ),
    );
  }
}
