import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_collection_query.dart';
import 'package:roamly_app/src/features/home/presentation/controllers/destination_collection_controller.dart';
import 'package:roamly_app/src/features/home/presentation/state/destination_collection_state.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/destination_collection_skeleton.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/destination_card.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../constants/home_layout.dart';

class DestinationCollectionPage extends ConsumerWidget {
  const DestinationCollectionPage({
    super.key,
    required this.title,
    required this.query,
    required this.onDestinationSelected,
  });
  final String title;
  final DestinationCollectionQuery query;
  final void Function(BuildContext context, Destination destination)
  onDestinationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = destinationCollectionControllerProvider(query);
    final result = ref.watch(provider);
    Future<void> reload() async {
      await ref.read(provider.notifier).reload();
    }

    return RoamlyScaffold(
      appBar: AppBar(title: Text(title)),
      bodyPadding: EdgeInsets.zero,
      body: result.when(
        data: (collection) => RefreshIndicator.adaptive(
          onRefresh: reload,
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: (notification) {
              if (notification.depth == 0 &&
                  collection.canLoadMore &&
                  notification.metrics.extentAfter <
                      notification.metrics.viewportDimension / 2) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  ref.read(provider.notifier).loadMore();
                });
              }
              return false;
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                const padding = HomeLayout.gridPadding;
                const gap = HomeLayout.gridGap;
                final columns = HomeLayout.gridColumnCount(
                  constraints.maxWidth,
                );
                final rowCount = (collection.items.length / columns).ceil();
                return CustomScrollView(
                  key: PageStorageKey(query),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (collection.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(RoamlySpacing.space24),
                          child: Text(
                            AppStrings.homeEmpty,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(padding),

                        sliver: SliverList.builder(
                          itemCount: rowCount,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: gap),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (
                                    var column = 0;
                                    column < columns;
                                    column++
                                  ) ...[
                                    if (column > 0) const SizedBox(width: gap),
                                    Expanded(
                                      child: _cardAt(
                                        context,
                                        collection,
                                        index * columns + column,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: _PaginationFooter(
                        collection: collection,
                        onLoadMore: () {
                          ref.read(provider.notifier).loadMore();
                        },
                        onRetry: () {
                          ref.read(provider.notifier).retryLoadMore();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(RoamlySpacing.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  AppStrings.homeLoadFailed,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: RoamlySpacing.space16),
                RoamlyButton.ghost(
                  label: AppStrings.tryAgain,
                  onPressed: reload,
                ),
              ],
            ),
          ),
        ),
        skipLoadingOnRefresh: false,
        skipLoadingOnReload: false,
        loading: () => const SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: DestinationCollectionSkeleton(),
        ),
      ),
    );
  }

  Widget _cardAt(
    BuildContext context,
    DestinationCollectionState collection,
    int index,
  ) {
    if (index >= collection.items.length) {
      return const SizedBox.shrink();
    }
    final destination = collection.items[index];
    return DestinationCard(
      key: ValueKey(destination.id),
      destination: destination,
      variant: DestinationCardVariant.grid,
      onTap: () => onDestinationSelected(context, destination),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.collection,
    required this.onLoadMore,
    required this.onRetry,
  });
  final DestinationCollectionState collection;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (!collection.hasMore) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.all(RoamlySpacing.space16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (collection.isLoadingMore)
            const DestinationCollectionSkeleton(
              rowCount: 1,
              padding: EdgeInsets.zero,
            )
          else if (collection.loadMoreFailure != null) ...[
            const Text(
              AppStrings.homeLoadMoreFailed,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RoamlySpacing.space8),
            RoamlyButton.ghost(label: AppStrings.tryAgain, onPressed: onRetry),
          ] else
            RoamlyButton.ghost(
              label: AppStrings.homeLoadMore,
              onPressed: onLoadMore,
            ),
        ],
      ),
    );
  }
}
