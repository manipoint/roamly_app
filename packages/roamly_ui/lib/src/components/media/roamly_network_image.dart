import 'package:flutter/material.dart';

import '../../foundations/spacing/roamly_spacing.dart';
import '../feedback/roamly_skeleton.dart';

class RoamlyNetworkImage extends StatelessWidget {
  const RoamlyNetworkImage({
    super.key,
    required this.uri,
    this.altText,
    required this.fit,
    this.placeholderIconSize = RoamlySpacing.space32,
  });
  final Uri? uri;
  final String? altText;
  final BoxFit fit;
  final double placeholderIconSize;

  @override
  Widget build(BuildContext context) {
    final imageUri = uri;
    final colors = Theme.of(context).colorScheme;

    Widget placeholder() {
      return ColoredBox(
        color: colors.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.landscape_outlined,
            size: placeholderIconSize,
            color: colors.onSurfaceVariant,
          ),
        ),
      );
    }

    if (imageUri == null) return placeholder();
    return Image.network(
      imageUri.toString(),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      semanticLabel: altText,
      excludeFromSemantics: altText == null,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return ExcludeSemantics(
          child: RoamlySkeleton(
            width: double.infinity,
            height: double.infinity,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => placeholder(),
    );
  }
}
