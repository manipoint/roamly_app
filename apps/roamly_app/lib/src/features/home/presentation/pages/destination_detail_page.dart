import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_detail.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_app/src/navigation/app_routes.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../controllers/destination_detail_controller.dart';
import '../../domain/failures/destination_detail_failure.dart';
import '../support/open_destination_map.dart';
import 'destination_media_viewer_page.dart';
import '../widgets/destination_about_section.dart';
import '../widgets/destination_detail_body.dart';
import '../widgets/destination_detail_error_view.dart';
import '../widgets/destination_detail_loading_view.dart';
import '../widgets/destination_detail_page_frame.dart';
import '../widgets/destination_location_button.dart';
import '../widgets/destination_media_gallery.dart';
import '../widgets/destination_place_card.dart';

final class DestinationDetailPage extends ConsumerWidget {
  const DestinationDetailPage({
    super.key,
    required this.slug,
    this.initialTitle,
  });

  final String slug;
  final String? initialTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = destinationDetailControllerProvider(slug);
    final result = ref.watch(provider);
    return DestinationDetailPageFrame(
      onBack: () => context.pop(),
      body: result.when(
        data: (detail) => _DestinationDetailView(detail: detail),
        error: (error, _) {
          final presentation = _destinationErrorPresentation(error);
          return DestinationDetailErrorView(
            message: presentation.message,
            icon: Icons.travel_explore_outlined,
            onRetry: presentation.canRetry
                ? () => ref.read(provider.notifier).retry()
                : null,
          );
        },
        loading: () => const DestinationDetailLoadingView(),
      ),
    );
  }
}

final class _DestinationDetailView extends StatelessWidget {
  const _DestinationDetailView({required this.detail});
  final DestinationDetail detail;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gallery = detail.gallery
        .where((media) => media.id != detail.coverImage?.id)
        .toList(growable: false);

    return DestinationDetailBody(
      pageStorageKey: 'destination-${detail.slug}',
      coverImage: detail.coverImage,
      onCoverTap: detail.coverImage == null
          ? null
          : () async {
              await DestinationMediaViewerPage.show(
                context,
                title: detail.name,
                selectedMedia: detail.coverImage!,
                coverImage: detail.coverImage,
                gallery: detail.gallery,
              );
            },
      children: [
        Semantics(
          header: true,
          child: Text(detail.name, style: theme.textTheme.headlineMedium),
        ),
        const SizedBox(height: RoamlySpacing.space8),
        DestinationLocationButton(
          label: detail.countryName,
          onTap: () async {
            await openDestinationMap(
              context,
              title: detail.name,
              location: detail.location,
            );
          },
        ),
        const SizedBox(height: RoamlySpacing.space16),
        Text(detail.summary, style: theme.textTheme.titleMedium),
        const SizedBox(height: RoamlySpacing.space24),
        DestinationAboutSection(
          title: AppStrings.destinationAbout,
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
                title: detail.name,
                selectedMedia: media,
                coverImage: detail.coverImage,
                gallery: detail.gallery,
              );
            },
          ),
        ],
        if (detail.places.isNotEmpty) ...[
          const SizedBox(height: RoamlySpacing.space32),
          Semantics(
            header: true,
            child: Text(
              AppStrings.destinationPlaces,
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: RoamlySpacing.space12),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth * 0.88)
                  .clamp(280.0, 360.0)
                  .toDouble();
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < detail.places.length; i++) ...[
                      SizedBox(
                        width: cardWidth,
                        child: DestinationPlaceCard(
                          key: ValueKey(detail.places[i].id),
                          place: detail.places[i],
                          onTap: () {
                            context.pushNamed(
                              AppRouteNames.destinationPlaceDetail,
                              pathParameters: {
                                'slug': detail.slug,
                                'placeSlug': detail.places[i].slug,
                              },
                              extra: detail.places[i].name,
                            );
                          },
                        ),
                      ),
                      if (i != detail.places.length - 1)
                        const SizedBox(width: RoamlySpacing.space12),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

({String message, bool canRetry}) _destinationErrorPresentation(Object error) {
  final failure = error is DestinationDetailFailure ? error : null;

  final message = switch (failure?.kind) {
    DestinationDetailFailureKind.invalidSlug =>
      AppStrings.destinationDetailInvalid,
    DestinationDetailFailureKind.notFound =>
      AppStrings.destinationDetailNotFound,
    _ => AppStrings.destinationDetailLoadFailed,
  };

  final canRetry = switch (error) {
    DestinationDetailFailure failure =>
      failure.kind == DestinationDetailFailureKind.invalidResponse,
    AppFailure failure => failure.isRetryable,
    _ => false,
  };

  return (message: message, canRetry: canRetry);
}
