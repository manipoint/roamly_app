import 'package:flutter/material.dart';
import 'package:roamly_app/src/branding/widgets/roamly_app_icon.dart';
import 'package:roamly_app/src/features/home/presentation/constants/home_layout.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

final class HomeLoadingView extends StatelessWidget {
  const HomeLoadingView({super.key});

  static const loadingKey = ValueKey<String>('home-loading');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: AppStrings.homeLoading,
      child: ExcludeSemantics(
        child: CustomScrollView(
          key: loadingKey,
          physics: const NeverScrollableScrollPhysics(),
          slivers: const [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                RoamlySpacing.space16,
                RoamlySpacing.space12,
                RoamlySpacing.space16,
                RoamlySpacing.space16,
              ),
              sliver: SliverToBoxAdapter(child: _HomeLoadingHeader()),
            ),
            SliverToBoxAdapter(child: _CategoryLoadingRow()),
            SliverToBoxAdapter(child: SizedBox(height: RoamlySpacing.space16)),
            SliverToBoxAdapter(
              child: _HomeSectionLoading(
                title: AppStrings.homePopular,
                variant: _LoadingCardVariant.compact,
              ),
            ),
            SliverToBoxAdapter(
              child: _HomeSectionLoading(
                title: AppStrings.homeSuggested,
                variant: _LoadingCardVariant.editorial,
              ),
            ),
            SliverToBoxAdapter(
              child: _HomeSectionLoading(
                title: AppStrings.homeFeatured,
                variant: _LoadingCardVariant.compact,
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: RoamlySpacing.space24)),
          ],
        ),
      ),
    );
  }
}

final class _HomeLoadingHeader extends StatelessWidget {
  const _HomeLoadingHeader();

  static const double _searchHeight = 56;
  static const double _refreshPlaceholderSize = 24;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            const RoamlyAppIcon(size: RoamlySpacing.space40),
            const SizedBox(width: RoamlySpacing.space8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: AppStrings.appNamePrefix),
                    TextSpan(
                      text: AppStrings.appNameEmphasis,
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ],
                ),
                style: theme.textTheme.headlineSmall,
              ),
            ),
            SizedBox.square(
              dimension: RoamlySpacing.space48,
              child: Center(
                child: RoamlySkeleton(
                  width: _refreshPlaceholderSize,
                  height: _refreshPlaceholderSize,
                  borderRadius: RoamlyRadii.pill,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: RoamlySpacing.space20),
        RoamlySkeleton(
          width: double.infinity,
          height: _searchHeight,
          borderRadius: RoamlyRadii.large,
        ),
      ],
    );
  }
}

final class _CategoryLoadingRow extends StatelessWidget {
  const _CategoryLoadingRow();

  static const double _chipHeight = 40;
  static const _chipWidths = <double>[72, 108, 104, 100, 116];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: RoamlySpacing.space16),
      child: Row(
        children: [
          for (final width in _chipWidths)
            Padding(
              padding: const EdgeInsets.only(right: RoamlySpacing.space8),
              child: RoamlySkeleton(
                width: width,
                height: _chipHeight,
                borderRadius: RoamlyRadii.pill,
              ),
            ),
        ],
      ),
    );
  }
}

enum _LoadingCardVariant { compact, editorial }

final class _HomeSectionLoading extends StatelessWidget {
  const _HomeSectionLoading({required this.title, required this.variant});

  final String title;
  final _LoadingCardVariant variant;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: RoamlySpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: RoamlySpacing.space16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                RoamlySkeleton(
                  width: 56,
                  height: RoamlySpacing.space16,
                  borderRadius: RoamlyRadii.small,
                ),
              ],
            ),
          ),
          const SizedBox(height: RoamlySpacing.space12),
          if (variant == _LoadingCardVariant.compact)
            const _CompactCardsLoading()
          else
            const _EditorialCardLoading(),
        ],
      ),
    );
  }
}

final class _CompactCardsLoading extends StatelessWidget {
  const _CompactCardsLoading();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: RoamlySpacing.space16),
      child: Row(
        children: [
          for (
            var index = 0;
            index < HomeLayout.compactLoadingItemCount;
            index++
          ) ...[
            if (index > 0) const SizedBox(width: RoamlySpacing.space8),
            RoamlySkeleton(
              width: HomeLayout.compactPreferredWidth,
              height: HomeLayout.compactImageHeight + 86,
              borderRadius: RoamlyRadii.medium,
            ),
          ],
        ],
      ),
    );
  }
}

final class _EditorialCardLoading extends StatelessWidget {
  const _EditorialCardLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: RoamlySpacing.space16),
      child: RoamlySkeleton(
        width: double.infinity,
        height: HomeLayout.editorialMinHeight,
        borderRadius: RoamlyRadii.medium,
      ),
    );
  }
}
