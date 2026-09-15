import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_collection_query.dart';
import 'package:roamly_app/src/features/home/presentation/constants/home_layout.dart';
import 'package:roamly_app/src/features/home/presentation/pages/destination_collection_page.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/destination_card.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../domain/entities/destination.dart';

final class HomeDiscoverySection extends StatelessWidget {
  const HomeDiscoverySection({
    super.key,
    required this.title,
    required this.destinations,
    required this.query,
    required this.onDestinationSelected,
    this.editorial = false,
  });
  final String title;
  final List<Destination> destinations;
  final DestinationCollectionQuery? query;
  final bool editorial;
  final void Function(BuildContext context, Destination destination)
  onDestinationSelected;

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
                            onDestinationSelected(context, destinations[i]),
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
          onDestinationSelected: onDestinationSelected,
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
}
