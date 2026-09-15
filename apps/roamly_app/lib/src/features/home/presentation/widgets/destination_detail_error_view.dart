import 'package:flutter/material.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../../../localization/app_strings.dart';

final class DestinationDetailErrorView extends StatelessWidget {
  const DestinationDetailErrorView({
    super.key,
    required this.message,
    required this.icon,
    this.onRetry,
  });

  final String message;
  final IconData icon;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(RoamlySpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: RoamlySpacing.space48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: RoamlySpacing.space16),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: RoamlySpacing.space16),
              RoamlyButton.ghost(
                label: AppStrings.tryAgain,
                onPressed: onRetry!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
