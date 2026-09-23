import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message_delivery_state.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

final class AssistantMessageBubble extends StatelessWidget {
  const AssistantMessageBubble({super.key, required this.message});

  final AssistantMessage message;

  bool get _isUser => message.author == AssistantMessageAuthor.user;

  bool get _hasFailed {
    return message.deliveryState == AssistantMessageDeliveryState.failed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final backgroundColor = _isUser
        ? colors.primaryContainer
        : colors.surfaceContainerHighest;

    final foregroundColor = _isUser
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;

    return Semantics(
      container: true,
      label: _isUser
          ? AppStrings.assistantYourMessage
          : AppStrings.assistantResponse,
      child: Align(
        alignment: _isUser
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: math.min(MediaQuery.sizeOf(context).width * 0.82, 560.0),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: _bubbleBorderRadius,
              border: _hasFailed
                  ? Border.all(color: colors.error, width: 1.5)
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: RoamlySpacing.space16,
                vertical: RoamlySpacing.space12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: _isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SelectableText(
                      message.content,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: foregroundColor,
                      ),
                    ),
                  ),
                  if (_isUser) ...[
                    const SizedBox(height: RoamlySpacing.space4),
                    _AssistantDeliveryIndicator(state: message.deliveryState),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BorderRadiusGeometry get _bubbleBorderRadius {
    const largeRadius = Radius.circular(18);
    const smallRadius = Radius.circular(4);

    return _isUser
        ? const BorderRadiusDirectional.only(
            topStart: largeRadius,
            topEnd: largeRadius,
            bottomStart: largeRadius,
            bottomEnd: smallRadius,
          )
        : const BorderRadiusDirectional.only(
            topStart: largeRadius,
            topEnd: largeRadius,
            bottomStart: smallRadius,
            bottomEnd: largeRadius,
          );
  }
}

final class _AssistantDeliveryIndicator extends StatelessWidget {
  const _AssistantDeliveryIndicator({required this.state});

  final AssistantMessageDeliveryState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final presentation = _presentation;

    final color = state == AssistantMessageDeliveryState.failed
        ? colors.error
        : colors.onPrimaryContainer.withValues(alpha: 0.72);

    return Tooltip(
      message: presentation.label,
      child: Icon(
        presentation.icon,
        size: 16,
        color: color,
      ),
    );
  }

  ({IconData icon, String label}) get _presentation {
    return switch (state) {
      AssistantMessageDeliveryState.pending => (
        icon: Icons.schedule_rounded,
        label: AppStrings.assistantMessagePending,
      ),
      AssistantMessageDeliveryState.sent => (
        icon: Icons.check_rounded,
        label: AppStrings.assistantMessageSent,
      ),
      AssistantMessageDeliveryState.processing => (
        icon: Icons.more_horiz_rounded,
        label: AppStrings.assistantMessageProcessing,
      ),
      AssistantMessageDeliveryState.completed => (
        icon: Icons.done_all_rounded,
        label: AppStrings.assistantMessageCompleted,
      ),
      AssistantMessageDeliveryState.failed => (
        icon: Icons.error_outline_rounded,
        label: AppStrings.assistantMessageFailed,
      ),
    };
  }
}
