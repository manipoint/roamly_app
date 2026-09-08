import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/canonical_location.dart';
import 'package:roamly_app/src/features/preferences/domain/failures/location_resolution_failure.dart';
import 'package:roamly_app/src/features/preferences/domain/repositories/location_resolution_repository.dart';
import 'package:roamly_app/src/features/preferences/presentation/controllers/location_search_controller.dart';
import 'package:roamly_app/src/features/preferences/presentation/providers/preference_dependency_providers.dart';
import 'package:roamly_app/src/features/preferences/presentation/state/location_search_state.dart';
import 'package:roamly_core/roamly_core.dart';

const _lahore = CanonicalLocation(
  provider: 'google',
  providerLocationId: 'lahore-id',
  canonicalName: 'Lahore, Punjab, Pakistan',
  countryCode: 'PK',
  latitude: 31.5204,
  longitude: 74.3587,
);

const _london = CanonicalLocation(
  provider: 'google',
  providerLocationId: 'london-id',
  canonicalName: 'London, England, United Kingdom',
  countryCode: 'GB',
  latitude: 51.5072,
  longitude: -0.1276,
);

final class _Request {
  _Request({required this.query, required this.limit});

  final String query;
  final int limit;
  final completer = Completer<Result<List<CanonicalLocation>>>();
}

final class _Repository implements LocationResolutionRepository {
  final List<_Request> requests = <_Request>[];

  @override
  Future<Result<List<CanonicalLocation>>> resolve({
    required String query,
    int limit = 5,
  }) {
    final request = _Request(query: query, limit: limit);
    requests.add(request);
    return request.completer.future;
  }
}

void main() {
  late _Repository repository;
  late ProviderContainer container;
  late ProviderSubscription<LocationSearchState> subscription;
  late LocationSearchController controller;
  late bool isDisposed;

  setUp(() {
    repository = _Repository();
    container = ProviderContainer(
      overrides: [
        locationResolutionRepositoryProvider.overrideWithValue(repository),
      ],
    );
    subscription = container.listen<LocationSearchState>(
      locationSearchControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    controller = container.read(locationSearchControllerProvider.notifier);
    isDisposed = false;
  });

  tearDown(() {
    if (isDisposed) return;
    subscription.close();
    container.dispose();
  });

  testWidgets('waits for debounce and collapses rapid query changes', (
    tester,
  ) async {
    controller.search('  Lah  ');
    await tester.pump(const Duration(milliseconds: 250));
    controller.search('  Lahore  ');

    await tester.pump(const Duration(milliseconds: 399));
    expect(repository.requests, isEmpty);
    expect(container.read(locationSearchControllerProvider).query, 'Lahore');

    await tester.pump(const Duration(milliseconds: 1));
    expect(repository.requests, hasLength(1));
    expect(repository.requests.single.query, 'Lahore');
    expect(
      container.read(locationSearchControllerProvider).status,
      LocationSearchStatus.loading,
    );
  });

  testWidgets('short and overlong queries never invoke the repository', (
    tester,
  ) async {
    controller.search('L');
    await tester.pump(LocationSearchController.debounceDuration);
    expect(repository.requests, isEmpty);
    expect(
      container.read(locationSearchControllerProvider).status,
      LocationSearchStatus.idle,
    );

    controller.search(List<String>.filled(121, 'x').join());
    await tester.pump(LocationSearchController.debounceDuration);
    expect(repository.requests, isEmpty);
    expect(
      container.read(locationSearchControllerProvider).failure,
      isA<LocationResolutionFailure>(),
    );
  });

  testWidgets('maps successful and empty results to explicit states', (
    tester,
  ) async {
    controller.search('Lahore');
    await tester.pump(LocationSearchController.debounceDuration);
    repository.requests.single.completer.complete(
      const Success<List<CanonicalLocation>>(<CanonicalLocation>[_lahore]),
    );
    await tester.pump();

    var state = container.read(locationSearchControllerProvider);
    expect(state.status, LocationSearchStatus.success);
    expect(state.options, <CanonicalLocation>[_lahore]);

    controller.search('Unknown place');
    await tester.pump(LocationSearchController.debounceDuration);
    repository.requests.last.completer.complete(
      const Success<List<CanonicalLocation>>(<CanonicalLocation>[]),
    );
    await tester.pump();

    state = container.read(locationSearchControllerProvider);
    expect(state.status, LocationSearchStatus.empty);
    expect(state.query, 'Unknown place');
  });

  testWidgets('ignores an older response after a newer search starts', (
    tester,
  ) async {
    controller.search('Lahore');
    await tester.pump(LocationSearchController.debounceDuration);

    controller.search('London');
    await tester.pump(LocationSearchController.debounceDuration);
    expect(repository.requests, hasLength(2));

    repository.requests[1].completer.complete(
      const Success<List<CanonicalLocation>>(<CanonicalLocation>[_london]),
    );
    await tester.pump();
    repository.requests[0].completer.complete(
      const Success<List<CanonicalLocation>>(<CanonicalLocation>[_lahore]),
    );
    await tester.pump();

    final state = container.read(locationSearchControllerProvider);
    expect(state.query, 'London');
    expect(state.options, <CanonicalLocation>[_london]);
  });

  testWidgets('same failed query only repeats through explicit retry', (
    tester,
  ) async {
    controller.search('Lahore');
    await tester.pump(LocationSearchController.debounceDuration);
    repository.requests.single.completer.complete(
      const FailureResult<List<CanonicalLocation>>(
        LocationResolutionFailure.invalidResponse(),
      ),
    );
    await tester.pump();

    controller.search(' Lahore ');
    await tester.pump(LocationSearchController.debounceDuration);
    expect(repository.requests, hasLength(1));

    controller.retry();
    await tester.pump(LocationSearchController.debounceDuration);
    expect(repository.requests, hasLength(2));
  });

  testWidgets('clear invalidates an in-flight response', (tester) async {
    controller.search('Lahore');
    await tester.pump(LocationSearchController.debounceDuration);

    controller.clear();
    repository.requests.single.completer.complete(
      const Success<List<CanonicalLocation>>(<CanonicalLocation>[_lahore]),
    );
    await tester.pump();

    final state = container.read(locationSearchControllerProvider);
    expect(state.status, LocationSearchStatus.idle);
    expect(state.query, isEmpty);
    expect(state.options, isEmpty);
  });

  testWidgets('disposing before debounce prevents repository work', (
    tester,
  ) async {
    controller.search('Lahore');
    subscription.close();
    container.dispose();
    isDisposed = true;

    await tester.pump(LocationSearchController.debounceDuration);

    expect(repository.requests, isEmpty);
    expect(tester.takeException(), isNull);
  });

  test('success state owns an immutable copy of its options', () {
    final input = <CanonicalLocation>[_lahore];
    final state = LocationSearchState.success(query: 'Lahore', options: input);

    input.clear();

    expect(state.options, <CanonicalLocation>[_lahore]);
    expect(() => state.options.clear(), throwsUnsupportedError);
    expect(
      () => const LocationSearchState.empty(query: 'none').options.add(_lahore),
      throwsUnsupportedError,
    );
  });
}
