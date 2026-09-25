import 'package:flutter/material.dart';
import 'package:roamly_app/src/features/home/presentation/constants/home_layout.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../../../localization/app_strings.dart';
import '../../domain/entities/media_asset.dart';
import 'destination_media_image.dart';

final class DestinationDetailBody extends StatelessWidget {
  const DestinationDetailBody({
    super.key,
    required this.pageStorageKey,
    required this.coverImage,
    required this.children,
    this.onCoverTap,
  });

  final String pageStorageKey;
  final MediaAsset? coverImage;
  final List<Widget> children;
  final VoidCallback? onCoverTap;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: PageStorageKey<String>(pageStorageKey),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: AspectRatio(
            aspectRatio: HomeLayout.heroImageAspectRatio,
            child: _CoverImage(media: coverImage, onTap: onCoverTap),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            RoamlySpacing.space20,
            RoamlySpacing.space24,
            RoamlySpacing.space20,
            RoamlySpacing.space40,
          ),
          sliver: SliverList.list(children: children),
        ),
      ],
    );
  }
}

final class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.media, required this.onTap});

  final MediaAsset? media;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
final image = DestinationMediaImage(
      media: media,
      boxFit: BoxFit.cover,
      showBottomFade: true,
      bottomFadeColor: Theme.of(context).scaffoldBackgroundColor,
    );
    final onTap = this.onTap;
    if (media == null || onTap == null) return image;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '${media!.altText}, ${AppStrings.viewImageFullScreen}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: image),
      ),
    );
  }
}
