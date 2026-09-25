import 'package:flutter/material.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../domain/entities/media_asset.dart';

final class DestinationMediaImage extends StatelessWidget {
  const DestinationMediaImage({
    super.key,
    required this.media,
    this.boxFit = BoxFit.cover,
    this.showBottomFade = false,
    this.bottomFadeColor,
    this.bottomFadeHeightFactor = 0.42,
  }) : assert(
         bottomFadeHeightFactor >= 0 && bottomFadeHeightFactor <= 1,
         'bottomFadeHeightFactor must be between 0 and 1.',
       );

  final MediaAsset? media;
  final BoxFit boxFit;

  /// Enables a gradient that blends the bottom of the image into its layout.
  final bool showBottomFade;

  /// Should normally match the background immediately below the image.
  final Color? bottomFadeColor;

  final double bottomFadeHeightFactor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final media = this.media;

    final image = media == null
        ? _placeholder(colors)
        : Image.network(
            media.uri.toString(),
            fit: boxFit,
            semanticLabel: media.altText,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                return child;
              }

              return ColoredBox(
                color: colors.surfaceContainerHighest,
                child: const Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _placeholder(colors);
            },
          );

    if (!showBottomFade) {
      return image;
    }

    final fadeColor =
        bottomFadeColor ?? Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  widthFactor: 1,
                  heightFactor: bottomFadeHeightFactor,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          fadeColor.withValues(alpha: 0),
                          fadeColor.withValues(alpha: 0.55),
                          fadeColor,
                        ],
                        stops: const [0, 0.75, 1],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
