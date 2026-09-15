import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_collection_query.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_detail.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_page.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_place_detail.dart';
import 'package:roamly_app/src/features/home/domain/entities/home_discovery.dart';
import 'package:roamly_app/src/features/home/domain/repositories/home_discovery_repository.dart';
import 'package:roamly_app/src/features/home/presentation/pages/destination_collection_page.dart';
import 'package:roamly_app/src/features/home/presentation/providers/home_dependency_providers.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/destination_card.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/destination_collection_skeleton.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/preference_types.dart';
import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_networking/roamly_networking.dart';
import 'package:roamly_ui/roamly_ui.dart';

Destination _item(String id) => Destination(
  id: id,
  slug: id,
  name: id,
  countryName: 'Pakistan',
  countryCode: 'PK',
  summary: 'Mountains and local culture',
  imageUri: Uri.parse('https://example.test/$id.jpg'),
  imageAlt: id,
  latitude: 0,
  longitude: 0,
  budgetTier: BudgetTier.midRange,
  styles: const [TravelStyle.nature],
  interests: const [TravelInterest.hiking],
);
Result<DestinationPage> _page(List<String> ids, {String? cursor}) =>
    Success(DestinationPage(items: ids.map(_item), nextCursor: cursor));
const _failure = NetworkFailure(
  code: 'network_timeout',
  isRetryable: true,
  kind: NetworkFailureKind.timeout,
);

class _Repository implements HomeDiscoveryRepository {
  final cursors = <String?>[];
  Future<Result<DestinationPage>> Function(String?) respond = (_) async =>
      _page(['Hunza']);
  @override
  Future<Result<DestinationPage>> getDestinations({
    required DestinationCollectionQuery query,
    int limit = 20,
    String? cursor,
  }) {
    cursors.add(cursor);
    return respond(cursor);
  }

  @override
  Future<Result<HomeDiscovery>> getHome({required int limit}) =>
      throw StateError('Unexpected Home request');

  @override
  Future<Result<DestinationDetail>> getDestinationDetail({
    required String slug,
  }) => throw StateError('Unexpected destination detail request');

  @override
  Future<Result<DestinationPlaceDetail>> getDestinationPlaceDetail({
    required String destinationSlug,
    required String placeSlug,
  }) => throw StateError('Unexpected destination place detail request');
}

void main() {
  late _Repository repository;
  final selected = <Destination>[];
  setUp(() {
    repository = _Repository();
    selected.clear();
  });
  Future<void> pump(
    WidgetTester tester, {
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeDiscoveryRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: RoamlyTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: DestinationCollectionPage(
            title: 'Popular',
            query: const DestinationCollectionQuery.popular(),
            onDestinationSelected: (_, destination) =>
                selected.add(destination),
          ),
        ),
      ),
    );
  }

  testWidgets('initial loading renders cards and taps return destination', (
    tester,
  ) async {
    final pending = Completer<Result<DestinationPage>>();
    repository.respond = (_) => pending.future;
    await pump(tester);
    expect(find.byType(DestinationCard), findsNothing);
    expect(find.byType(DestinationCollectionSkeleton), findsOneWidget);
    expect(find.byType(RoamlySkeleton), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.bySemanticsLabel(AppStrings.homeLoading), findsOneWidget);
    pending.complete(_page(['Hunza']));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DestinationCard));
    expect(selected.single.id, 'Hunza');
    expect(repository.cursors, [null]);
    expect(tester.takeException(), isNull);
  });
  testWidgets('load-more uses one responsive skeleton row', (tester) async {
    repository.respond = (_) async => _page(['Hunza'], cursor: 'next');
    await pump(tester);
    await tester.pumpAndSettle();

    final pending = Completer<Result<DestinationPage>>();
    repository.respond = (_) => pending.future;
    await tester.tap(find.text(AppStrings.homeLoadMore));
    await tester.pump();

    expect(find.text('Hunza'), findsOneWidget);
    expect(find.byType(DestinationCollectionSkeleton), findsOneWidget);
    expect(find.byType(RoamlySkeleton), findsNWidgets(2));
    expect(find.byType(CircularProgressIndicator), findsNothing);

    pending.complete(_page(['Skardu']));
    await tester.pumpAndSettle();
    expect(find.byType(DestinationCollectionSkeleton), findsNothing);
    expect(find.text('Skardu'), findsOneWidget);
  });
  testWidgets('initial error retries into empty state', (tester) async {
    repository.respond = (_) async => const FailureResult(_failure);
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.homeLoadFailed), findsOneWidget);
    repository.respond = (_) async => _page([]);
    await tester.tap(find.text(AppStrings.tryAgain));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.homeEmpty), findsOneWidget);
    expect(repository.cursors, [null, null]);
  });
  testWidgets('load-more failure retains cards and explicit retry appends', (
    tester,
  ) async {
    repository.respond = (_) async => _page(['Hunza'], cursor: 'next');
    await pump(tester);
    await tester.pumpAndSettle();
    repository.respond = (_) async => const FailureResult(_failure);
    await tester.tap(find.text(AppStrings.homeLoadMore));
    await tester.pumpAndSettle();
    expect(find.text('Hunza'), findsOneWidget);
    expect(find.text(AppStrings.homeLoadMoreFailed), findsOneWidget);
    repository.respond = (_) async => _page(['Skardu']);
    await tester.tap(find.text(AppStrings.tryAgain));
    await tester.pumpAndSettle();
    expect(find.text('Skardu'), findsOneWidget);
    expect(find.text(AppStrings.homeLoadMore), findsNothing);
    expect(repository.cursors, [null, 'next', 'next']);
    expect(tester.takeException(), isNull);
  });
  testWidgets('refresh awaits request completion and replaces cards', (
    tester,
  ) async {
    await pump(tester);
    await tester.pumpAndSettle();
    final pending = Completer<Result<DestinationPage>>();
    repository.respond = (_) => pending.future;
    var completed = false;
    final refresh = tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh()
        .then((_) => completed = true);
    await tester.pump();
    expect(completed, isFalse);
    pending.complete(_page(['Skardu']));
    await refresh;
    await tester.pumpAndSettle();
    expect(find.text('Hunza'), findsNothing);
    expect(find.text('Skardu'), findsOneWidget);
  });
  testWidgets('scroll near end loads the next page once', (tester) async {
    repository.respond = (cursor) async => cursor == null
        ? _page(List.generate(8, (i) => 'Place$i'), cursor: 'next')
        : _page(['Last']);
    await pump(tester);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(repository.cursors, [null, 'next']);
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 1024.0]) {
    testWidgets('responsive rows render at width $width with large text', (
      tester,
    ) async {
      repository.respond = (_) async => _page(['Hunza', 'Skardu', 'Lahore']);
      await pump(tester, width: width, scale: 2);
      await tester.pumpAndSettle();
      expect(find.byType(DestinationCard), findsWidgets);
      expect(tester.takeException(), isNull);
      final first = tester.getRect(find.byKey(const ValueKey('Hunza')));
      final second = tester.getRect(find.byKey(const ValueKey('Skardu')));
      if (width == 320) {
        expect(second.top, greaterThanOrEqualTo(first.bottom));
      } else {
        expect(second.top, first.top);
        expect(second.left, greaterThan(first.left));
      }
    });
  }
}
