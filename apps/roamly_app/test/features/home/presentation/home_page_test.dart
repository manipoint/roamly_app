import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:roamly_app/src/features/home/domain/entities/destination_collection_query.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_detail.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_page.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_place_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_collection.dart';
import 'package:roamly_app/src/features/home/domain/entities/home_discovery.dart';
import 'package:roamly_app/src/features/home/domain/entities/map_location.dart';
import 'package:roamly_app/src/features/home/domain/failures/home_discovery_failure.dart';
import 'package:roamly_app/src/features/home/domain/repositories/home_discovery_repository.dart';
import 'package:roamly_app/src/features/home/presentation/pages/destination_collection_page.dart';
import 'package:roamly_app/src/features/home/presentation/pages/destination_detail_page.dart';
import 'package:roamly_app/src/features/home/presentation/pages/home_page.dart';
import 'package:roamly_app/src/features/home/presentation/constants/home_layout.dart';
import 'package:roamly_app/src/features/home/presentation/providers/home_dependency_providers.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/destination_card.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/home_discovery_section.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/home_loading_view.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_app/src/navigation/app_routes.dart';
import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_ui/roamly_ui.dart';

Destination _destination(String name, TravelStyle style) => Destination(
  id: name,
  slug: name.toLowerCase(),
  name: name,
  countryName: name == 'Kyoto' ? 'Japan' : 'Indonesia',
  countryCode: name == 'Kyoto' ? 'JP' : 'ID',
  summary: 'Discover beautiful landscapes and local culture.',
  imageUri: Uri.parse('https://example.test/$name.jpg'),
  imageAlt: '$name landscape',
  latitude: 0,
  longitude: 0,
  budgetTier: BudgetTier.midRange,
  styles: [style],
  interests: const [TravelInterest.photography],
);

HomeDiscovery _data({bool empty = false}) {
  final items = empty
      ? <Destination>[]
      : [
          _destination('Bali', TravelStyle.beaches),
          _destination('Kyoto', TravelStyle.culture),
          _destination('Lombok', TravelStyle.nature),
        ];
  return HomeDiscovery(
    personalizationReady: !empty,
    popular: items,
    suggested: items.take(1),
    spotlight: DestinationCollection(
      kind: DiscoveryCollectionKind.featured,
      items: items,
    ),
  );
}

DestinationDetail _detail(String slug) {
  final isKyoto = slug == 'kyoto';
  return DestinationDetail(
    id: isKyoto
        ? '00000000-0000-4000-8000-000000000002'
        : '00000000-0000-4000-8000-000000000001',
    slug: slug,
    name: isKyoto ? 'Kyoto' : 'Bali',
    type: isKyoto ? DestinationType.city : DestinationType.island,
    countryName: isKyoto ? 'Japan' : 'Indonesia',
    countryCode: isKyoto ? 'JP' : 'ID',
    summary: 'Discover beautiful landscapes and local culture.',
    fullDescription:
        'Explore historic landmarks, local traditions, and scenic landscapes.',
    location: const MapLocation(latitude: 0, longitude: 0, mapZoom: 9),
    budgetTier: BudgetTier.midRange,
    styles: [isKyoto ? TravelStyle.culture : TravelStyle.beaches],
    interests: const [TravelInterest.photography],
    gallery: const [],
    places: const [],
    placesNextCursor: null,
  );
}

final class _Repository implements HomeDiscoveryRepository {
  @override
  Future<Result<DestinationPage>> getDestinations({
    required DestinationCollectionQuery query,
    int limit = 20,
    String? cursor,
  }) async {
    catalogueQueries.add(query);
    return Success(
      DestinationPage(
        items: [_destination('Kyoto', TravelStyle.culture)],
        nextCursor: null,
      ),
    );
  }

  final catalogueQueries = <DestinationCollectionQuery>[];
  final detailSlugs = <String>[];

  int calls = 0;
  Result<HomeDiscovery> result = Success(_data());
  Completer<Result<HomeDiscovery>>? pending;
  @override
  Future<Result<HomeDiscovery>> getHome({required int limit}) async {
    calls++;
    return pending?.future ?? result;
  }

  @override
  Future<Result<DestinationDetail>> getDestinationDetail({
    required String slug,
  }) async {
    detailSlugs.add(slug);
    return Success(_detail(slug));
  }

  @override
  Future<Result<DestinationPlaceDetail>> getDestinationPlaceDetail({
    required String destinationSlug,
    required String placeSlug,
  }) {
    throw StateError('Unexpected destination place detail request.');
  }
}

void main() {
  setUpAll(() async {
    final textFont = FontLoader('packages/roamly_ui/Inter')
      ..addFont(
        rootBundle.load('packages/roamly_ui/assets/fonts/Inter-Variable.ttf'),
      );
    final iconsFont = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([textFont.load(), iconsFont.load()]);
  });
  late _Repository repository;
  setUp(() => repository = _Repository());

  Future<void> pump(
    WidgetTester tester, {
    double scale = 1,
    bool dark = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const RepaintBoundary(
            key: ValueKey('home-preview'),
            child: RoamlyScaffold(
              bodyPadding: EdgeInsets.zero,
              body: HomePage(),
            ),
          ),
        ),
        GoRoute(
          path: '${AppRoutePaths.home}/${AppRoutePaths.destinationDetail}',
          name: AppRouteNames.destinationDetail,
          builder: (context, state) {
            final initialTitle = state.extra;
            return DestinationDetailPage(
              slug: state.pathParameters['slug']!,
              initialTitle: initialTitle is String ? initialTitle : null,
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeDiscoveryRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          theme: dark ? RoamlyTheme.dark : RoamlyTheme.light,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      ),
    );
  }

  testWidgets('loading becomes ranked discovery sections', (tester) async {
    final pending = Completer<Result<HomeDiscovery>>();
    repository.pending = pending;
    await pump(tester);
    expect(find.byKey(HomeLoadingView.loadingKey), findsOneWidget);
    expect(find.byType(RoamlySkeleton), findsWidgets);
    expect(
      tester
          .widgetList<RoamlySkeleton>(find.byType(RoamlySkeleton))
          .where(
            (skeleton) =>
                skeleton.width == HomeLayout.compactPreferredWidth &&
                skeleton.height == HomeLayout.compactImageHeight + 86,
          ),
      hasLength(HomeLayout.compactLoadingItemCount * 2),
    );
    pending.complete(Success(_data()));
    await tester.pumpAndSettle();
    expect(find.byKey(HomeLoadingView.loadingKey), findsNothing);
    expect(find.text(AppStrings.homePopular), findsOneWidget);
    expect(find.text(AppStrings.homeSuggested), findsOneWidget);
    final firstSection = find.byType(HomeDiscoverySection).first;
    final cards = tester
        .widgetList<DestinationCard>(
          find.descendant(
            of: firstSection,
            matching: find.byType(DestinationCard),
          ),
        )
        .toList();
    expect(
      tester
          .getSize(
            find
                .descendant(
                  of: firstSection,
                  matching: find.byType(DestinationCard),
                )
                .first,
          )
          .width,
      HomeLayout.compactPreferredWidth,
    );
    expect(cards.take(2).map((card) => card.destination.name), [
      'Bali',
      'Kyoto',
    ]);
    expect(find.byIcon(Icons.landscape_outlined), findsWidgets);
    expect(repository.calls, 1);

    const path = String.fromEnvironment('HOME_PREVIEW_PATH');
    if (path.isNotEmpty) {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('home-preview')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(path).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });

  testWidgets('safe error and explicit retry recover', (tester) async {
    repository.result = const FailureResult(
      HomeDiscoveryFailure.invalidResponse(),
    );
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.homeLoadFailed), findsOneWidget);
    repository.result = Success(_data(empty: true));
    await tester.tap(find.text(AppStrings.tryAgain));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.homeEmpty), findsOneWidget);
    expect(repository.calls, 2);
  });

  testWidgets('search and category filters do not issue extra requests', (
    tester,
  ) async {
    await pump(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Kyoto');
    await tester.pumpAndSettle();
    expect(find.byType(DestinationCard), findsWidgets);
    expect(
      tester
          .widgetList<DestinationCard>(find.byType(DestinationCard))
          .every((card) => card.destination.name == 'Kyoto'),
      isTrue,
    );
    await tester.tap(find.text(AppStrings.travelStyleBeaches));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.homeNoMatches), findsOneWidget);
    await tester.tap(find.text(AppStrings.homeClearFilters));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.homePopular), findsOneWidget);
    expect(repository.calls, 1);
  });

  testWidgets('view all and destination details expose real content', (
    tester,
  ) async {
    await pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.homeViewAll).first);
    await tester.pumpAndSettle();
    expect(find.byType(DestinationCollectionPage), findsOneWidget);
    expect(repository.catalogueQueries, [
      const DestinationCollectionQuery.popular(),
    ]);
    await tester.tap(find.byType(DestinationCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(DestinationDetailPage), findsOneWidget);
    expect(find.text('Japan'), findsWidgets);
    expect(
      find.text('Discover beautiful landscapes and local culture.'),
      findsWidgets,
    );
    expect(repository.detailSlugs, ['kyoto']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct card tap opens the destination detail route', (
    tester,
  ) async {
    await pump(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DestinationCard).first);
    await tester.pumpAndSettle();
    final page = find.byType(DestinationDetailPage);
    expect(page, findsOneWidget);
    expect(
      find.descendant(of: page, matching: find.text('Bali')),
      findsWidgets,
    );
    final summary = find.text(
      'Discover beautiful landscapes and local culture.',
    );
    expect(summary, findsOneWidget);
    final text = tester.widget<Text>(summary);
    expect(text.maxLines, isNull);
    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(repository.detailSlugs, ['bali']);
    expect(repository.calls, 1);
    expect(tester.takeException(), isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(DestinationDetailPage), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
  });

  for (final variant in DestinationCardVariant.values) {
    testWidgets(
      '$variant grows with typography and keeps the whole card tappable',
      (tester) async {
        int taps = 0;
        Future<void> render(double scale) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: RoamlyTheme.light,
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: 280,
                        child: DestinationCard(
                          destination: _destination(
                            'Kyoto',
                            TravelStyle.culture,
                          ),
                          variant: variant,
                          decoration: BoxDecoration(
                            border: Border.all(width: 4),
                            borderRadius: const BorderRadiusDirectional.only(
                              topStart: Radius.circular(20),
                            ),
                          ),
                          titleStyle: const TextStyle(fontSize: 22),
                          summaryStyle: const TextStyle(fontSize: 18),
                          onTap: () => taps++,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        await render(1);
        final originalHeight = tester
            .getSize(find.byType(DestinationCard))
            .height;
        await render(2);
        final rect = tester.getRect(find.byType(DestinationCard));
        expect(rect.height, greaterThan(originalHeight));
        expect(rect.width, 280);
        expect(tester.takeException(), isNull);
        await tester.tapAt(rect.topLeft + const Offset(30, 30));
        await tester.tapAt(rect.bottomRight - const Offset(30, 30));
        expect(taps, 2);
      },
    );
  }

  testWidgets('pull to refresh requests new data', (tester) async {
    repository.result = Success(_data(empty: true));
    await pump(tester);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('home-page')),
      const Offset(0, 450),
    );
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
  });

  testWidgets('large text and dark theme render without overflow', (
    tester,
  ) async {
    await pump(tester, scale: 2, dark: true);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(AppStrings.homeFeatured),
      150,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('home-page')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(tester.takeException(), isNull);
  });
}
