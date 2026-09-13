import 'package:flutter/material.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../domain/entities/destination.dart';
import '../constants/home_layout.dart';
import 'home_destination_image.dart';

enum DestinationCardVariant { compact, editorial, grid }

final class DestinationCard extends StatelessWidget {
   DestinationCard({
    super.key,
    required this.destination,
    required this.onTap,
    this.variant = DestinationCardVariant.compact,
    this.decoration,
    this.titleStyle,
    this.subtitleStyle,
    this.summaryStyle,
  }) : assert(
         decoration == null || decoration.shape == BoxShape.rectangle,
         'Destination cards require rectangular decoration.',
       );

  final Destination destination;
  final VoidCallback onTap;
  final DestinationCardVariant variant;

  final BoxDecoration? decoration;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final TextStyle? summaryStyle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final resolvedDecoration =
        decoration ??
        BoxDecoration(
          color: colors.surface,
          borderRadius: RoamlyRadii.medium,
          border: Border.all(color: colors.outlineVariant),
        );

    final borderRadius = (resolvedDecoration.borderRadius ?? BorderRadius.zero)
        .resolve(Directionality.of(context));

    final copy = _DestinationCopy(
      destination: destination,
      variant: variant,
      titleStyle: titleStyle,
      subtitleStyle: subtitleStyle,
      summaryStyle: summaryStyle,
    );

    final image = HomeDestinationImage(destination: destination);

    final content = switch (variant) {
      DestinationCardVariant.compact => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: HomeLayout.compactImageHeight, child: image),
          copy,
        ],
      ),
      DestinationCardVariant.grid => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: HomeLayout.gridImageAspectRatio,
            child: image,
          ),
          copy,
        ],
      ),
      DestinationCardVariant.editorial => _EditorialLayout(
        image: image,
        copy: copy,
      ),
    };

    return Semantics(
      container: true,
      button: true,
      label: '${destination.name}, ${destination.countryName}',
      child: DecoratedBox(
        decoration: resolvedDecoration,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            children: [
              // This non-positioned child determines the card height.
              Padding(
                padding: resolvedDecoration.padding,
                child: ExcludeSemantics(child: content),
              ),

              // The interaction layer follows the actual content size.
              Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(borderRadius: borderRadius, onTap: onTap),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


final class _EditorialLayout extends StatelessWidget {
  const _EditorialLayout({required this.image, required this.copy});

  final Widget image;
  final Widget copy;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        assert(
          constraints.hasBoundedWidth,
          'Editorial cards need a bounded width.',
        );

        final imageWidth = constraints.maxWidth / 2;

        return Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: imageWidth),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: HomeLayout.editorialMinHeight,
                    ),
                    child: copy,
                  ),
                ),
              ],
            ),
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              width: imageWidth,
              child: image,
            ),
          ],
        );
      },
    );
  }
}


final class _DestinationCopy extends StatelessWidget {
  const _DestinationCopy({
    required this.destination,
    required this.variant,
    this.titleStyle,
    this.subtitleStyle,
    this.summaryStyle,
  });

  final Destination destination;
  final DestinationCardVariant variant;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final TextStyle? summaryStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final fallback = DefaultTextStyle.of(context).style;

    final compact = variant == DestinationCardVariant.compact;
    final editorial = variant == DestinationCardVariant.editorial;

    final defaultTitle = compact
        ? (textTheme.bodySmall ?? fallback).copyWith(
            fontWeight: FontWeight.w600,
          )
        : textTheme.titleMedium ?? fallback;

    final defaultBody = (textTheme.bodySmall ?? fallback).copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final titleLines = switch (variant) {
      DestinationCardVariant.compact => HomeLayout.compactTitleLines,
      DestinationCardVariant.editorial => HomeLayout.editorialTitleLines,
      DestinationCardVariant.grid => HomeLayout.gridTitleLines,
    };

    final summaryLines = switch (variant) {
      DestinationCardVariant.compact => HomeLayout.compactSummaryLines,
      DestinationCardVariant.editorial => HomeLayout.editorialSummaryLines,
      DestinationCardVariant.grid => HomeLayout.gridSummaryLines,
    };

    return Padding(
      padding: EdgeInsets.all(
        compact ? RoamlySpacing.space8 : RoamlySpacing.space12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: editorial
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Text(
            destination.name,
            maxLines: titleLines,
            overflow: TextOverflow.ellipsis,
            style: defaultTitle.merge(titleStyle),
          ),
          const SizedBox(height: RoamlySpacing.space4),
          Text(
            destination.countryName,
            maxLines: HomeLayout.countryLines,
            overflow: TextOverflow.ellipsis,
            style: defaultBody.merge(subtitleStyle),
          ),
          const SizedBox(height: RoamlySpacing.space4),
          Text(
            destination.summary,
            maxLines: summaryLines,
            overflow: TextOverflow.ellipsis,
            style: defaultBody.merge(summaryStyle),
          ),
        ],
      ),
    );
  }
}
