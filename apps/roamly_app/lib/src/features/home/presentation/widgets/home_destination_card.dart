import 'package:flutter/material.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../domain/entities/destination.dart';

/// A compact portrait card or a wide editorial recommendation.
final class HomeDestinationCard extends StatelessWidget {
  const HomeDestinationCard({
    super.key,
    required this.destination,
    required this.onTap,
    this.editorial = false,
  });

  static const double portraitImageHeight = 136;
  final Destination destination;
  final VoidCallback onTap;
  final bool editorial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final copy = Padding(
      padding: const EdgeInsets.all(RoamlySpacing.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            destination.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: RoamlySpacing.space4),
          Text(
            destination.countryName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: RoamlySpacing.space8),
          Text(
            destination.summary,
            maxLines: editorial ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      label: '${destination.name}, ${destination.countryName}',
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: RoamlyRadii.medium,
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ExcludeSemantics(
            child: editorial
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: HomeDestinationImage(destination: destination),
                      ),
                      Expanded(child: copy),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: portraitImageHeight,
                        child: HomeDestinationImage(destination: destination),
                      ),
                      Expanded(child: copy),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

final class HomeDestinationImage extends StatelessWidget {
  const HomeDestinationImage({super.key, required this.destination});
  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Image.network(
      destination.imageUri.toString(),
      fit: BoxFit.cover,
      semanticLabel: destination.imageAlt,
      frameBuilder: (context, child, frame, synchronous) =>
          synchronous || frame != null
          ? child
          : ColoredBox(color: colors.surfaceContainerHighest),
      errorBuilder: (_, _, _) => ColoredBox(
        color: colors.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.landscape_outlined,
            size: RoamlySpacing.space32,
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
