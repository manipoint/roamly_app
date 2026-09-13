import 'package:roamly_app/src/features/home/domain/entities/destination_collection_query.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_page.dart';
import 'package:roamly_app/src/features/home/data/models/destination_page_model.dart';
import 'package:roamly_app/src/features/home/domain/failures/destination_catalogue_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/data/models/home_discovery_model.dart';
import 'package:roamly_app/src/features/home/data/repositories/default_home_discovery_repository.dart';
import 'package:roamly_app/src/features/home/data/sources/home_remote_data_source.dart';
import 'package:roamly_app/src/features/home/domain/entities/home_discovery.dart';
import 'package:roamly_app/src/features/home/domain/failures/home_discovery_failure.dart';
import 'package:roamly_app/src/features/home/domain/policies/home_discovery_policy.dart';
import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_networking/roamly_networking.dart';

HomeDiscoveryModel _response() {
  return HomeDiscoveryModel.fromJson(<String, Object?>{
    'personalization_ready': false,
    'suggested': <Object?>[],
    'popular': <Object?>[],
    'spotlight': <String, Object?>{'kind': 'featured', 'items': <Object?>[]},
  });
}

final class _Source implements HomeRemoteDataSource {
  int calls = 0;
  int catalogueCalls = 0;
  DestinationCollectionQuery? query;
  String? cursor;
  final page = DestinationPageModel.fromJson({
    'items': <Object?>[],
    'next_cursor': null,
  });
  @override
  Future<DestinationPageModel> getDestinations({
    required DestinationCollectionQuery query,
    required int limit,
    String? cursor,
  }) async {
    catalogueCalls++;
    this.query = query;
    this.limit = limit;
    this.cursor = cursor;
    if (error case final value?) throw value;
    return page;
  }

  int? limit;
  Object? error;
  HomeDiscoveryModel response = _response();

  @override
  Future<HomeDiscoveryModel> getHome({required int limit}) async {
    calls++;
    this.limit = limit;
    if (error case final value?) {
      throw value;
    }
    return response;
  }
}

final class _Executor implements ApiRequestExecutor {
  int calls = 0;
  AppFailure? failure;

  @override
  Future<Result<T>> execute<T>(Future<T> Function() request) async {
    calls++;
    if (failure case final value?) {
      return FailureResult<T>(value);
    }
    return Success<T>(await request());
  }
}

void main() {
  late _Source source;
  late _Executor executor;
  late DefaultHomeDiscoveryRepository repository;

  setUp(() {
    source = _Source();
    executor = _Executor();
    repository = DefaultHomeDiscoveryRepository(
      remoteDataSource: source,
      requestExecutor: executor,
    );
  });

  void expectHomeFailure(
    Result<HomeDiscovery> result,
    HomeDiscoveryFailureKind kind,
  ) {
    expect(result, isA<FailureResult<HomeDiscovery>>());
    final failure = (result as FailureResult<HomeDiscovery>).failure;
    expect(failure, isA<HomeDiscoveryFailure>());
    expect((failure as HomeDiscoveryFailure).kind, kind);
  }

  group('getDestinations', () {
    const query = DestinationCollectionQuery.popular();
    Future<Result<DestinationPage>> load({int limit = 20, String? cursor}) =>
        repository.getDestinations(query: query, limit: limit, cursor: cursor);
    void expectFailure(
      Result<DestinationPage> result,
      DestinationCatalogueFailureKind kind,
    ) {
      final failure = (result as FailureResult<DestinationPage>).failure;
      expect(failure, isA<DestinationCatalogueFailure>());
      expect((failure as DestinationCatalogueFailure).kind, kind);
    }

    test(
      'first page uses default limit and returns source page unchanged',
      () async {
        final result = await repository.getDestinations(query: query);
        expect(
          (result as Success<DestinationPage>).value,
          same(source.page.toDomain()),
        );
        expect(source.query, same(query));
        expect(source.limit, 20);
        expect(source.cursor, isNull);
        expect(source.catalogueCalls, 1);
        expect(source.calls, 0);
        expect(executor.calls, 1);
      },
    );
    test(
      'forwards continuation cursor unchanged with the query and limit',
      () async {
        const suggested = DestinationCollectionQuery.suggested();
        await repository.getDestinations(
          query: suggested,
          limit: 50,
          cursor: 'opaque_-cursor',
        );
        expect(source.query, same(suggested));
        expect(source.limit, 50);
        expect(source.cursor, 'opaque_-cursor');
        expect(source.catalogueCalls, 1);
        expect(executor.calls, 1);
      },
    );
    test('accepts minimum and maximum page sizes', () async {
      for (final limit in [1, 50]) {
        expect(await load(limit: limit), isA<Success<DestinationPage>>());
        expect(source.limit, limit);
      }
      expect(source.catalogueCalls, 2);
    });
    test('invalid limits and cursor lengths avoid all network work', () async {
      for (final limit in [0, -1, 51]) {
        expectFailure(
          await load(limit: limit),
          DestinationCatalogueFailureKind.invalidLimit,
        );
      }
      for (final cursor in ['', 'a' * 513]) {
        expectFailure(
          await load(cursor: cursor),
          DestinationCatalogueFailureKind.invalidCursor,
        );
      }
      expect(executor.calls, 0);
      expect(source.catalogueCalls, 0);
    });
    test(
      'maps only HTTP 422 invalid_cursor to the catalogue failure',
      () async {
        executor.failure = const NetworkFailure(
          code: 'request_validation_failed',
          kind: NetworkFailureKind.validation,
          isRetryable: false,
          statusCode: 422,
          backendCode: 'invalid_cursor',
        );
        expectFailure(
          await load(cursor: 'stale'),
          DestinationCatalogueFailureKind.invalidCursor,
        );
        expect(executor.calls, 1);
      },
    );
    test('preserves other validation and network failures unchanged', () async {
      for (final failure in [
        const NetworkFailure(
          code: 'request_validation_failed',
          kind: NetworkFailureKind.validation,
          isRetryable: false,
          statusCode: 422,
        ),
        const NetworkFailure(
          code: 'request_validation_failed',
          kind: NetworkFailureKind.validation,
          isRetryable: false,
          statusCode: 422,
          backendCode: 'invalid_limit',
        ),
        const NetworkFailure(
          code: 'request_validation_failed',
          kind: NetworkFailureKind.validation,
          isRetryable: false,
          statusCode: 400,
          backendCode: 'invalid_cursor',
        ),
        const NetworkFailure(
          code: 'network_timeout',
          kind: NetworkFailureKind.timeout,
          isRetryable: true,
        ),
        const NetworkFailure(
          code: 'unauthorized',
          kind: NetworkFailureKind.unauthorized,
          isRetryable: false,
          statusCode: 401,
        ),
      ]) {
        executor.failure = failure;
        expect(
          ((await load()) as FailureResult<DestinationPage>).failure,
          same(failure),
        );
      }
      expect(executor.calls, 5);
    });
    test('maps malformed responses without retrying', () async {
      source.error = const FormatException('bad response');
      expectFailure(
        await load(),
        DestinationCatalogueFailureKind.invalidResponse,
      );
      expect(source.catalogueCalls, 1);
      expect(executor.calls, 1);
    });
    test('propagates unexpected programming errors', () async {
      final error = StateError('bug');
      source.error = error;
      await expectLater(load(), throwsA(same(error)));
    });
  });

  test('returns server-ranked discovery and forwards the limit', () async {
    final result = await repository.getHome(limit: 4);

    expect(executor.calls, 1);
    expect(source.calls, 1);
    expect(source.limit, 4);
    expect(
      (result as Success<HomeDiscovery>).value,
      same(source.response.toDomain()),
    );
  });

  test('invalid limits avoid executor and remote work', () async {
    for (final limit in <int>[
      HomeDiscoveryPolicy.minimumSectionLimit - 1,
      HomeDiscoveryPolicy.maximumSectionLimit + 1,
    ]) {
      expectHomeFailure(
        await repository.getHome(limit: limit),
        HomeDiscoveryFailureKind.invalidLimit,
      );
    }

    expect(executor.calls, 0);
    expect(source.calls, 0);
  });

  test('malformed successful responses become safe feature failures', () async {
    source.error = const FormatException('malformed response');

    expectHomeFailure(
      await repository.getHome(limit: 4),
      HomeDiscoveryFailureKind.invalidResponse,
    );
    expect(executor.calls, 1);
    expect(source.calls, 1);
  });

  test('executor failures are preserved unchanged', () async {
    const failure = NetworkFailure(
      code: 'request_timeout',
      isRetryable: true,
      kind: NetworkFailureKind.timeout,
    );
    executor.failure = failure;

    final result = await repository.getHome(limit: 4);

    expect((result as FailureResult<HomeDiscovery>).failure, same(failure));
    expect(executor.calls, 1);
    expect(source.calls, 0);
  });

  test('programming errors are not disguised as expected failures', () async {
    final error = StateError('bug');
    source.error = error;

    await expectLater(repository.getHome(limit: 4), throwsA(same(error)));
  });
}
