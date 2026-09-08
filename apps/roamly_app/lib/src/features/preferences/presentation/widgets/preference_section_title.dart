import 'package:flutter/material.dart';

/// Consistent heading for one preference-selection group.
final class PreferenceSectionTitle extends StatelessWidget {
  const PreferenceSectionTitle({
    super.key,
    required this.title,
    this.information,
  });

  final String title;
  final String? information;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (information case final message?) ...[
          const SizedBox(width: 4),
          Tooltip(
            message: message,
            child: Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
