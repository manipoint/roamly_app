import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_collection_query.dart';
import 'package:roamly_app/src/features/home/presentation/constants/home_layout.dart';
import 'package:roamly_app/src/features/home/presentation/pages/destination_collection_page.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/destination_card.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';
import 'home_destination_image.dart';
import '../../domain/entities/destination.dart';

class HomeDiscoverySection extends StatelessWidget {
  const HomeDiscoverySection({
    super.key,
    required this.title,
    required this.destinations,
    required this.query,
    this.editorial = false,
  });
  final String title;
  final List<Destination> destinations;
  final DestinationCollectionQuery? query;
  final bool editorial;

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) {
      return const SizedBox.shrink();
    }

    final variant = editorial
        ? DestinationCardVariant.editorial
        : DestinationCardVariant.compact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RoamlySpacing.space16,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (query != null)
                RoamlyButton.ghost(
                  label: AppStrings.homeViewAll,
                  onPressed: () => _showAll(context),
                ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = math.max(
              0.0,
              constraints.maxWidth - RoamlySpacing.space16 * 2,
            );
            if (availableWidth == 0) {
              return const SizedBox.shrink();
            }
            final cardWidth = _cardWidth(availableWidth);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              primary: false,
              padding: const EdgeInsets.symmetric(
                horizontal: RoamlySpacing.space16,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < destinations.length; i++) ...[
                    if (i > 0) const SizedBox(width: RoamlySpacing.space8),
                    SizedBox(
                      width: cardWidth,
                      child: DestinationCard(
                        key: ValueKey(destinations[i].id),
                        destination: destinations[i],
                        variant: variant,
                        onTap: () =>
                            showHomeDestination(context, destinations[i]),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: RoamlySpacing.space16),
      ],
    );
  }

  Future<void> _showAll(BuildContext context) async {
    final collectionQuery = query;
    if (collectionQuery == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DestinationCollectionPage(
          title: title,
          query: collectionQuery,
          onDestinationSelected: showHomeDestination,
        ),
      ),
    );
  }

  double _cardWidth(double availableWidth) {
    if (editorial) {
      return availableWidth
          .clamp(HomeLayout.editorialMinWidth, HomeLayout.editorialMaxWidth)
          .toDouble();
    }

    final preferredWidth = HomeLayout.compactPreferredWidth.clamp(
      HomeLayout.compactMinWidth,
      HomeLayout.compactMaxWidth,
    );
    return math.min(availableWidth, preferredWidth).toDouble();
  }

  void showHomeDestination(BuildContext context, Destination destination) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            RoamlySpacing.space20,
            RoamlySpacing.space20,
            RoamlySpacing.space20,
            RoamlySpacing.space24 + bottomInset,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: RoamlyRadii.large,
                child: AspectRatio(
                  aspectRatio: HomeLayout.gridImageAspectRatio,
                  child: HomeDestinationImage(destination: destination),
                ),
              ),
              const SizedBox(height: RoamlySpacing.space20),
              Semantics(
                header: true,
                child: Text(
                  destination.name,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: RoamlySpacing.space4),
              Text(
                destination.countryName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: RoamlySpacing.space16),
              Text(destination.summary, style: theme.textTheme.bodyMedium),
            ],
          ),
        );
      },
    );
  }
}
