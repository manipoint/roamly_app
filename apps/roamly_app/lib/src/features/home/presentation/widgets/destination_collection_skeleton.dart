import 'package:flutter/material.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../constants/home_layout.dart';

/// Reusable responsive loading grid for destination catalogue screens.
///
/// It uses the same column, padding, gap, and image-ratio contract as the
/// populated destination grid, so every View All screen has matching loading
/// geometry.
final class DestinationCollectionSkeleton extends StatelessWidget {
  const DestinationCollectionSkeleton({
    super.key,
    this.rowCount = 4,
    this.padding = const EdgeInsets.all(HomeLayout.gridPadding),
  }) : assert(rowCount > 0);

  static const loadingKey = ValueKey<String>('destination-collection-loading');
  static const double _copyPlaceholderHeight = 88;

  final int rowCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: loadingKey,
      container: true,
      liveRegion: true,
      label: AppStrings.homeLoading,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final resolvedPadding = padding.resolve(Directionality.of(context));
            final columns = HomeLayout.gridColumnCountForAvailableWidth(
              constraints.maxWidth - resolvedPadding.horizontal,
            );
            return Padding(
              padding: padding,
              child: Column(
                children: [
                  for (var row = 0; row < rowCount; row++) ...[
                    if (row > 0) const SizedBox(height: HomeLayout.gridGap),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var column = 0; column < columns; column++) ...[
                          if (column > 0)
                            const SizedBox(width: HomeLayout.gridGap),
                          const Expanded(child: _DestinationGridCardSkeleton()),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

final class _DestinationGridCardSkeleton extends StatelessWidget {
  const _DestinationGridCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight =
            constraints.maxWidth / HomeLayout.gridImageAspectRatio;
        return RoamlySkeleton(
          width: double.infinity,
          height:
              imageHeight +
              DestinationCollectionSkeleton._copyPlaceholderHeight,
          borderRadius: RoamlyRadii.medium,
        );
      },
    );
  }
}
