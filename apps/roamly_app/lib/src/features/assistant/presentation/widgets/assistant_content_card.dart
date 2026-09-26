import 'package:flutter/material.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../domain/entities/assistant_rich_content.dart';
import '../constants/assistant_layout.dart';

/// Shared visual frame for Assistant place and hotel cards.
///
/// [details] follow the subtitle and provide their own leading gaps. When
/// [onTap] is supplied, details should be noninteractive: the whole card is
/// one accessible action.
final class AssistantContentCard extends StatelessWidget {
  const AssistantContentCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.image,
    this.imageAspectRatio = AssistantLayout.cardImageAspectRatio,
    this.details = const [],
    this.onTap,
  }) : assert(imageAspectRatio > 0 && imageAspectRatio < double.infinity);

  final String title;
  final String subtitle;
  final AssistantMedia? image;
  final double imageAspectRatio;
  final List<Widget> details;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final card = Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: RoamlyRadii.medium,
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: imageAspectRatio,
                child: RoamlyNetworkImage(
                  uri: image?.uri,
                  altText: image?.altText,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(RoamlySpacing.space12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    RoamlyGap.h4,
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    ...details,
                  ],
                ),
              ),
            ],
          ),
          if (onTap != null)
            Positioned.fill(
              child: ExcludeSemantics(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(onTap: onTap),
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return card;
    return MergeSemantics(
      child: Semantics(button: true, onTap: onTap, child: card),
    );
  }
}
