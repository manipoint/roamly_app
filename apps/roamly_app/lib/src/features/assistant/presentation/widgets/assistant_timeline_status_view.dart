import 'package:flutter/material.dart';
import 'package:roamly_ui/roamly_ui.dart';

final class AssistantTimelineStatusView extends StatelessWidget {
  const AssistantTimelineStatusView({
    super.key,
    required this.icon,
    required this.message,
    this.iconColor,
    this.actionLabel,
    this.onAction,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction must either both be set or both be null.',
       );

  final IconData icon;
  final String message;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(RoamlySpacing.space24),
        child: Column(
          key: const ValueKey<String>('assistant-timeline-status'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: iconColor ?? Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: RoamlySpacing.space12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onAction case final action?) ...[
              const SizedBox(height: RoamlySpacing.space16),
              RoamlyButton.secondary(label: actionLabel!, onPressed: action),
            ],
          ],
        ),
      ),
    );
  }
}
