import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../constants/assistant_layout.dart';

/// Horizontal layout for the Assistant's bounded card collections.
final class AssistantContentCarousel extends StatelessWidget {
  const AssistantContentCarousel({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
  }) : assert(itemCount >= 0);

  final String title;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : AssistantLayout.carouselCardMaxWidth;

        final cardWidth = math.min(
          itemCount == 1
              ? availableWidth
              : availableWidth * AssistantLayout.carouselCardViewportFraction,
          AssistantLayout.carouselCardMaxWidth,
        );

        return SizedBox(
          width: availableWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              RoamlyGap.h8,
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index < itemCount; index++) ...[
                      if (index > 0) RoamlyGap.w8,
                      SizedBox(
                        width: cardWidth,
                        child: itemBuilder(context, index),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
