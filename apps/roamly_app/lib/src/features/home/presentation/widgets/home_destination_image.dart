import 'package:flutter/material.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../domain/entities/destination.dart';

class HomeDestinationImage extends StatelessWidget {
  const HomeDestinationImage({super.key, required this.destination});
  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Image.network(
      destination.imageUri.toString(),
      fit: BoxFit.cover,
      semanticLabel: destination.imageAlt,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return ColoredBox(color: colors.surfaceContainerHighest);
      },
      errorBuilder: (context, error, stackTrace) {
        return ColoredBox(
          color: colors.surfaceContainerHighest,
          child: Center(
            child: Icon(
              Icons.landscape_outlined,
              size: RoamlySpacing.space32,
              color: colors.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}
