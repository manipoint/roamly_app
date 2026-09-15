import 'package:flutter/material.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../domain/entities/media_asset.dart';
import 'destination_media_image.dart';

final class DestinationMediaGallery extends StatelessWidget {
  const DestinationMediaGallery({
    super.key,
    required this.title,
    required this.media,
    this.onMediaTap,
  });

  final String title;
  final List<MediaAsset> media;
  final ValueChanged<MediaAsset>? onMediaTap;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: theme.textTheme.titleLarge),
        ),
        const SizedBox(height: RoamlySpacing.space12),
        LayoutBuilder(
          builder: (context, constraints) {
            final imageWidth = (constraints.maxWidth * 0.82)
                .clamp(240.0, 360.0)
                .toDouble();

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (var index = 0; index < media.length; index++) ...[
                    SizedBox(
                      width: imageWidth,
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ClipRRect(
                          borderRadius: RoamlyRadii.medium,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onMediaTap == null
                                  ? null
                                  : () => onMediaTap!(media[index]),
                              child: DestinationMediaImage(
                                media: media[index],
                                boxFit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (index != media.length - 1)
                      const SizedBox(width: RoamlySpacing.space12),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
