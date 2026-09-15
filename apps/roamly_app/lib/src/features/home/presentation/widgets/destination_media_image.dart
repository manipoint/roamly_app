import 'package:flutter/material.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../domain/entities/media_asset.dart';

final class DestinationMediaImage extends StatelessWidget {
  const DestinationMediaImage({
    super.key,
    required this.media,
    this.boxFit = BoxFit.cover,
  });
  final MediaAsset? media;
  final BoxFit boxFit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final media = this.media;
    if (media == null) {
      return _placeholder(colors);
    }
    return Image.network(
      media.uri.toString(),
      fit: boxFit,
      semanticLabel: media.altText,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return ColoredBox(
          color: colors.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator.adaptive()),
        );
      },
      errorBuilder: (context, error, stackTrace) => _placeholder(colors),
    );
  }

  Widget _placeholder(ColorScheme colors) {
    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.landscape_outlined,
          size: RoamlySpacing.space48,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
