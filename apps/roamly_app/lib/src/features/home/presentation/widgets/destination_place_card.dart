import 'package:flutter/material.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/destination_media_image.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../domain/entities/destination_detail.dart';

class DestinationPlaceCard extends StatelessWidget {
  const DestinationPlaceCard({
    super.key,
    required this.place,
    required this.onTap,
  });
  final DestinationPlacePreview place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final address = place.address;
    return Semantics(
      button: true,
      container: true,
      label: address == null ? place.name : '${place.name}, $address',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: RoamlyRadii.medium,
        ),
        child: ClipRRect(
          borderRadius: RoamlyRadii.medium,
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: DestinationMediaImage(
                      media: place.coverImage,
                      boxFit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(RoamlySpacing.space12),
                    child: _PlaceCopy(place: place),
                  ),
                ],
              ),
              Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: RoamlyRadii.medium,
                    onTap: onTap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceCopy extends StatelessWidget {
  const _PlaceCopy({required this.place});
  final DestinationPlacePreview place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final address = place.address;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                place.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (place.isFeatured) ...[
              const SizedBox(width: RoamlySpacing.space8),
              Icon(
                Icons.star_rounded,
                size: RoamlySpacing.space20,
                color: colors.primary,
                semanticLabel: 'Featured',
              ),
            ],
          ],
        ),
        const SizedBox(height: RoamlySpacing.space4),
        Text(
          _formatPlaceType(place.placeType),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(color: colors.primary),
        ),
        if (address != null) ...[
          const SizedBox(height: RoamlySpacing.space8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: RoamlySpacing.space16,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: RoamlySpacing.space4),
              Expanded(
                child: Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: RoamlySpacing.space8),
        Text(
          place.summary,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatPlaceType(String placeType) {
    return placeType
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
