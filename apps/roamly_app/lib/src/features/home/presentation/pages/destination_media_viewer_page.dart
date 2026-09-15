import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../../../localization/app_strings.dart';
import '../../domain/entities/media_asset.dart';
import '../widgets/destination_media_image.dart';

final class DestinationMediaViewerPage extends StatefulWidget {
  const DestinationMediaViewerPage({
    super.key,
    required this.title,
    required this.media,
    required this.initialIndex,
  }) : assert(media.length > 0),
       assert(initialIndex >= 0 && initialIndex < media.length);

  final String title;
  final List<MediaAsset> media;
  final int initialIndex;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required MediaAsset selectedMedia,
    required MediaAsset? coverImage,
    required Iterable<MediaAsset> gallery,
  }) async {
    final orderedMedia = _uniqueMedia(coverImage, gallery);
    final initialIndex = orderedMedia.indexWhere(
      (media) => media.id == selectedMedia.id,
    );
    if (initialIndex < 0) return;

    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => DestinationMediaViewerPage(
          title: title,
          media: orderedMedia,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  static List<MediaAsset> _uniqueMedia(
    MediaAsset? coverImage,
    Iterable<MediaAsset> gallery,
  ) {
    final ids = <String>{};
    final media = <MediaAsset>[];

    void add(MediaAsset item) {
      if (ids.add(item.id)) media.add(item);
    }

    if (coverImage != null) add(coverImage);
    for (final item in gallery) {
      add(item);
    }

    return List<MediaAsset>.unmodifiable(media);
  }

  @override
  State<DestinationMediaViewerPage> createState() =>
      _DestinationMediaViewerPageState();
}

final class _DestinationMediaViewerPageState
    extends State<DestinationMediaViewerPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.media.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                final media = widget.media[index];
                return Semantics(
                  image: true,
                  excludeSemantics: true,
                  label: media.altText,
                  child: InteractiveViewer(
                    key: ValueKey<String>('media-viewer-${media.id}'),
                    minScale: 1,
                    maxScale: 4,
                    child: SizedBox.expand(
                      child: Center(
                        child: DestinationMediaImage(
                          media: media,
                          boxFit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(RoamlySpacing.space12),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).backButtonTooltip,
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: RoamlySpacing.space12),
                      Expanded(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: RoamlySpacing.space24,
              child: SafeArea(
                top: false,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: RoamlyRadii.large,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: RoamlySpacing.space12,
                        vertical: RoamlySpacing.space8,
                      ),
                      child: Text(
                        AppStrings.mediaPosition(
                          _currentIndex + 1,
                          widget.media.length,
                        ),
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
