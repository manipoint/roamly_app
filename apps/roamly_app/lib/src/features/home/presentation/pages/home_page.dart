import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_collection_query.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../../../branding/widgets/roamly_app_icon.dart';
import '../../../../localization/app_strings.dart';
import '../../../preferences/domain/entities/preference_types.dart';
import '../../domain/entities/destination.dart';
import '../../domain/entities/destination_collection.dart';
import '../../domain/entities/home_discovery.dart';
import '../controllers/home_discovery_controller.dart';
import '../widgets/home_discovery_section.dart';
import '../widgets/home_loading_view.dart';

final class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

final class _HomePageState extends ConsumerState<HomePage> {
  final _search = TextEditingController();
  TravelStyle? _style;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await ref.read(homeDiscoveryControllerProvider.notifier).reload();
  }

  void _clearFilters() {
    setState(() {
      _search.clear();
      _style = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final discovery = ref.watch(homeDiscoveryControllerProvider);
    if (discovery.isLoading && !discovery.hasValue) {
      return const HomeLoadingView();
    }

    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _reload,
      child: CustomScrollView(
        key: const ValueKey<String>('home-page'),
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              RoamlySpacing.space16,
              RoamlySpacing.space12,
              RoamlySpacing.space16,
              RoamlySpacing.space16,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
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
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        tooltip: AppStrings.homeRefresh,
                        onPressed: discovery.isLoading ? null : _reload,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: RoamlySpacing.space20),
                  Semantics(
                    label: AppStrings.homeSearchScope,
                    child: RoamlyTextFormField(
                      controller: _search,
                      hint: AppStrings.homeSearchHint,
                      textInputAction: TextInputAction.search,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: AppStrings.homeClearFilters,
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.close),
                            ),
                      onChanged: (_) => setState(() {}),
                      onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: RoamlySpacing.space16,
              ),
              child: Row(
                children: [
                  _chip(
                    null,
                    AppStrings.homeAllCategories,
                    Icons.explore_outlined,
                  ),
                  _chip(
                    TravelStyle.beaches,
                    AppStrings.travelStyleBeaches,
                    Icons.beach_access_outlined,
                  ),
                  _chip(
                    TravelStyle.culture,
                    AppStrings.travelStyleCulture,
                    Icons.account_balance_outlined,
                  ),
                  _chip(
                    TravelStyle.nature,
                    AppStrings.travelStyleNature,
                    Icons.landscape_outlined,
                  ),
                  _chip(
                    TravelStyle.adventure,
                    AppStrings.travelStyleAdventure,
                    Icons.hiking_outlined,
                  ),
                  _chip(
                    TravelStyle.food,
                    AppStrings.travelStyleFood,
                    Icons.restaurant_outlined,
                  ),
                  _chip(
                    TravelStyle.luxury,
                    AppStrings.travelStyleLuxury,
                    Icons.diamond_outlined,
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: RoamlySpacing.space8),
          ),
          ...discovery.when<List<Widget>>(
            skipLoadingOnRefresh: true,
            skipLoadingOnReload: true,
            loading: () => const <Widget>[],
            error: (_, _) => [
              _message(
                AppStrings.homeLoadFailed,
                action: AppStrings.tryAgain,
                onPressed: _reload,
              ),
            ],
            data: _sections,
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: RoamlySpacing.space24),
          ),
        ],
      ),
    );
  }

  Widget _chip(TravelStyle? style, String label, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    final selected = _style == style;
    final accent = style == TravelStyle.beaches || style == TravelStyle.nature
        ? colors.tertiary
        : colors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: RoamlySpacing.space8),
      child: ChoiceChip(
        label: Text(label),
        avatar: Icon(
          icon,
          size: RoamlySpacing.space16,
          color: selected ? colors.onPrimaryContainer : accent,
        ),
        selected: selected,
        showCheckmark: false,
        backgroundColor: accent.withValues(alpha: 0.06),
        selectedColor: colors.primaryContainer,
        labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: selected ? colors.onPrimaryContainer : accent,
        ),
        shape: const StadiumBorder(),
        side: BorderSide(
          color: selected ? colors.primary : accent.withValues(alpha: 0.15),
        ),
        onSelected: (_) => setState(() => _style = selected ? null : style),
      ),
    );
  }

  List<Destination> _filter(List<Destination> items) {
    final query = _search.text.trim().toLowerCase();
    return items
        .where(
          (destination) =>
              (_style == null || destination.styles.contains(_style)) &&
              (query.isEmpty ||
                  '${destination.name} ${destination.countryName} ${destination.summary}'
                      .toLowerCase()
                      .contains(query)),
        )
        .toList();
  }

  List<Widget> _sections(HomeDiscovery discovery) {
    final popular = _filter(discovery.popular);
    final suggested = _filter(discovery.suggested);
    final featured = _filter(discovery.spotlight.items);
    if (popular.isEmpty && suggested.isEmpty && featured.isEmpty) {
      final filtered = _style != null || _search.text.trim().isNotEmpty;
      return [
        _message(
          filtered ? AppStrings.homeNoMatches : AppStrings.homeEmpty,
          action: filtered
              ? AppStrings.homeClearFilters
              : AppStrings.homeRefresh,
          onPressed: filtered ? _clearFilters : _reload,
        ),
      ];
    }
    return [
      if (popular.isNotEmpty)
        SliverToBoxAdapter(
          child: HomeDiscoverySection(
            title: AppStrings.homePopular,
            destinations: popular,
            query: const DestinationCollectionQuery.popular(),
          ),
        ),
      if (suggested.isNotEmpty)
        SliverToBoxAdapter(
          child: HomeDiscoverySection(
            title: AppStrings.homeSuggested,
            destinations: suggested,
            editorial: true,
            query: DestinationCollectionQuery.suggested(),
          ),
        ),
      if (featured.isNotEmpty)
        SliverToBoxAdapter(
          child: HomeDiscoverySection(
            title: discovery.spotlight.kind == DiscoveryCollectionKind.featured
                ? AppStrings.homeFeatured
                : AppStrings.homeTrending,
            destinations: featured,
            query: discovery.spotlight.kind == DiscoveryCollectionKind.featured
                ? const DestinationCollectionQuery.featured()
                : null,
          ),
        ),
    ];
  }

  Widget _message(
    String text, {
    required String action,
    required VoidCallback onPressed,
  }) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(RoamlySpacing.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.travel_explore,
              size: RoamlySpacing.space40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: RoamlySpacing.space16),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: RoamlySpacing.space16),
            RoamlyButton.secondary(label: action, onPressed: onPressed),
          ],
        ),
      ),
    );
  }
}
