import 'package:flutter/material.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../domain/entities/canonical_location.dart';

final class LocationOptionTile extends StatelessWidget {
  const LocationOptionTile({
    super.key,
    required this.location,
    required this.onTap,
    this.isSelected = false,
  });

  final CanonicalLocation location;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return RoamlySelectableCard(
      key: ValueKey<String>(
        'location-option-${location.provider}-${location.providerLocationId}',
      ),
      isSelected: isSelected,
      onTap: onTap,
      semanticLabel: location.canonicalName,
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.all(RoamlySpacing.space12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.location_on_outlined, color: colors.primary),
          ),
          const SizedBox(width: RoamlySpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  location.canonicalName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: RoamlySpacing.space4),
                Text(
                  location.countryCode,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: RoamlySpacing.space8),
          Icon(
            isSelected ? Icons.check_circle : Icons.arrow_forward_ios_rounded,
            size: isSelected ? 22 : 16,
            color: isSelected ? colors.primary : colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
