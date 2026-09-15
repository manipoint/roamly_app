import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../../../localization/app_strings.dart';
import '../../domain/entities/destination_place_detail.dart';
import '../../domain/failures/destination_place_detail_failure.dart';
import '../controllers/destination_place_detail_controller.dart';
import '../support/open_destination_map.dart';
import 'destination_media_viewer_page.dart';
import '../widgets/destination_about_section.dart';
import '../widgets/destination_detail_body.dart';
import '../widgets/destination_detail_error_view.dart';
import '../widgets/destination_detail_loading_view.dart';
import '../widgets/destination_detail_page_frame.dart';
import '../widgets/destination_location_button.dart';
import '../widgets/destination_media_gallery.dart';

final class DestinationPlaceDetailPage extends ConsumerWidget {
  const DestinationPlaceDetailPage({
    super.key,
    required this.destinationSlug,
    required this.placeSlug,
    this.initialTitle,
  });

  final String destinationSlug;
  final String placeSlug;
  final String? initialTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = (destinationSlug: destinationSlug, placeSlug: placeSlug);

    final provider = destinationPlaceDetailControllerProvider(request);
    final result = ref.watch(provider);

    return DestinationDetailPageFrame(
      onBack: () => context.pop(),
      body: result.when(
        data: (detail) {
          return _DestinationPlaceDetailView(detail: detail);
        },
        loading: () {
          return const DestinationDetailLoadingView();
        },
        error: (error, _) {
          final presentation = _placeErrorPresentation(error);
          return DestinationDetailErrorView(
            message: presentation.message,
            icon: Icons.place_outlined,
            onRetry: presentation.canRetry
                ? () => ref.read(provider.notifier).retry()
                : null,
          );
        },
      ),
    );
  }
}

final class _DestinationPlaceDetailView extends StatelessWidget {
  const _DestinationPlaceDetailView({required this.detail});

  final DestinationPlaceDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final place = detail.place;
    final address = place.address;

    final gallery = detail.gallery
        .where((media) => media.id != detail.coverImage?.id)
        .toList(growable: false);

    return DestinationDetailBody(
      pageStorageKey:
          'destination-${detail.destinationSlug}-place-${place.slug}',
      coverImage: detail.coverImage,
      onCoverTap: detail.coverImage == null
          ? null
          : () async {
              await DestinationMediaViewerPage.show(
                context,
                title: place.name,
                selectedMedia: detail.coverImage!,
                coverImage: detail.coverImage,
                gallery: detail.gallery,
              );
            },
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(place.name, style: theme.textTheme.headlineMedium),
              ),
            ),
            if (place.isFeatured) ...[
              const SizedBox(width: RoamlySpacing.space12),
              Icon(
                Icons.star_rounded,
                color: theme.colorScheme.primary,
                semanticLabel: 'Featured',
              ),
            ],
          ],
        ),
        const SizedBox(height: RoamlySpacing.space4),
        Text(
          _formatPlaceType(place.placeType),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: RoamlySpacing.space8),
        DestinationLocationButton(
          label: address ?? place.name,
          onTap: () async {
            await openDestinationMap(
              context,
              title: place.name,
              location: place.location,
            );
          },
        ),
        const SizedBox(height: RoamlySpacing.space24),
        Text(place.summary, style: theme.textTheme.titleMedium),
        const SizedBox(height: RoamlySpacing.space24),
        DestinationAboutSection(
          title: AppStrings.destinationPlaceAbout,
          description: detail.fullDescription,
        ),
        if (gallery.isNotEmpty) ...[
          const SizedBox(height: RoamlySpacing.space32),
          DestinationMediaGallery(
            title: AppStrings.destinationGallery,
            media: gallery,
            onMediaTap: (media) async {
              await DestinationMediaViewerPage.show(
                context,
                title: place.name,
                selectedMedia: media,
                coverImage: detail.coverImage,
                gallery: detail.gallery,
              );
            },
          ),
        ],
      ],
    );
  }

  String _formatPlaceType(String value) {
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

({String message, bool canRetry}) _placeErrorPresentation(Object error) {
  final failure = error is DestinationPlaceDetailFailure ? error : null;

  final message = switch (failure?.kind) {
    DestinationPlaceDetailFailureKind.invalidDestinationSlug ||
    DestinationPlaceDetailFailureKind.invalidPlaceSlug =>
      AppStrings.destinationPlaceInvalid,
    DestinationPlaceDetailFailureKind.notFound =>
      AppStrings.destinationPlaceNotFound,
    _ => AppStrings.destinationPlaceLoadFailed,
  };

  final canRetry = switch (error) {
    DestinationPlaceDetailFailure failure =>
      failure.kind == DestinationPlaceDetailFailureKind.invalidResponse,
    AppFailure failure => failure.isRetryable,
    _ => false,
  };

  return (message: message, canRetry: canRetry);
}
