import 'package:roamly_app/src/features/home/data/models/destination_place_detail_model.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_collection_query.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_detail.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_page.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_place_detail.dart';
import 'package:roamly_app/src/features/home/data/models/destination_detail_model.dart';
import 'package:roamly_app/src/features/home/data/models/destination_page_model.dart';
import 'package:roamly_app/src/features/home/domain/failures/destination_catalogue_failure.dart';
import 'package:roamly_app/src/features/home/domain/failures/destination_detail_failure.dart';
import 'package:roamly_app/src/features/home/domain/failures/destination_place_detail_failure.dart';
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

DestinationDetailModel _detailResponse() {
  return DestinationDetailModel.fromJson(<String, Object?>{
    'id': '00000000-0000-4000-8000-000000000001',
    'slug': 'bali-indonesia',
    'name': 'Bali',
    'destination_type': 'island',
    'country_name': 'Indonesia',
    'country_code': 'ID',
    'summary': 'A tropical island rich in culture and natural beauty.',
    'full_description':
        'Explore beaches, temples, local traditions, and scenic landscapes.',
    'location': <String, Object?>{
      'latitude': -8.4095,
      'longitude': 115.1889,
      'map_zoom': 9,
    },
    'budget_tier': 'mid_range',
    'styles': <Object?>['beaches'],
    'interests': <Object?>['photography'],
    'gallery': <Object?>[],
    'places': <Object?>[],
    'places_next_cursor': null,
    'has_more_places': false,
  });
}

DestinationPlaceDetailModel _placeDetailResponse({
  String destinationSlug = 'tokyo-japan',
  String placeSlug = 'meiji-shrine',
}) {
  return DestinationPlaceDetailModel.fromJson(<String, Object?>{
    'id': '00000000-0000-4000-8000-000000000010',
    'slug': placeSlug,
    'name': 'Meiji Shrine',
    'place_type': 'religious_site',
    'summary': 'Visit a peaceful shrine surrounded by a large forest in Tokyo.',
    'location': <String, Object?>{
      'latitude': 35.6748,
      'longitude': 139.6996,
      'map_zoom': null,
    },
    'address': '1 Yoyogi Kamizonocho, Shibuya, Tokyo',
    'is_featured': true,
    'cover_image': null,
    'destination_slug': destinationSlug,
    'full_description':
        'Meiji Shrine is a peaceful Shinto shrine surrounded by a forest '
        'in the centre of Tokyo.',
    'gallery': <Object?>[],
  });
}

final class _Source implements HomeRemoteDataSource {
  int calls = 0;
  int catalogueCalls = 0;
  int detailCalls = 0;
  int placeDetailCalls = 0;
  String? detailSlug;
  String? placeDestinationSlug;
  String? placeSlug;
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
  DestinationDetailModel detailResponse = _detailResponse();
  DestinationPlaceDetailModel placeDetailResponse = _placeDetailResponse();

  @override
  Future<HomeDiscoveryModel> getHome({required int limit}) async {
    calls++;
    this.limit = limit;
    if (error case final value?) {
      throw value;
    }
    return response;
  }

  @override
  Future<DestinationDetailModel> getDestinationDetail({
    required String slug,
  }) async {
    detailCalls++;
    detailSlug = slug;
    if (error case final value?) {
      throw value;
    }
    return detailResponse;
  }

  @override
  Future<DestinationPlaceDetailModel> getDestinationPlaceDetail({
    required String destinationSlug,
    required String placeSlug,
  }) async {
    placeDetailCalls++;
    placeDestinationSlug = destinationSlug;
    this.placeSlug = placeSlug;
    if (error case final value?) {
      throw value;
    }
    return placeDetailResponse;
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

  group('getDestinationDetail', () {
    Future<Result<DestinationDetail>> load([String slug = 'bali-indonesia']) {
      return repository.getDestinationDetail(slug: slug);
    }

    void expectFailure(
      Result<DestinationDetail> result,
      DestinationDetailFailureKind kind,
    ) {
      expect(result, isA<FailureResult<DestinationDetail>>());
      final failure = (result as FailureResult<DestinationDetail>).failure;
      expect(failure, isA<DestinationDetailFailure>());
      expect((failure as DestinationDetailFailure).kind, kind);
    }

    test('normalizes a valid slug and returns the domain detail', () async {
      final result = await load('  bali-indonesia  ');

      expect(
        (result as Success<DestinationDetail>).value,
        same(source.detailResponse.toDomain()),
      );
      expect(source.detailSlug, 'bali-indonesia');
      expect(source.detailCalls, 1);
      expect(executor.calls, 1);
    });

    test('invalid slugs avoid executor and remote work', () async {
      for (final slug in ['', '   ', 'Bali Indonesia', '../bali']) {
        expectFailure(
          await load(slug),
          DestinationDetailFailureKind.invalidSlug,
        );
      }

      expect(executor.calls, 0);
      expect(source.detailCalls, 0);
    });

    test('maps only the documented not-found response', () async {
      executor.failure = const NetworkFailure(
        code: 'not_found',
        kind: NetworkFailureKind.notFound,
        isRetryable: false,
        statusCode: 404,
        backendCode: 'destination_not_found',
      );

      expectFailure(await load(), DestinationDetailFailureKind.notFound);
      expect(executor.calls, 1);
      expect(source.detailCalls, 0);
    });

    test('preserves unrelated network failures unchanged', () async {
      for (final failure in [
        const NetworkFailure(
          code: 'not_found',
          kind: NetworkFailureKind.notFound,
          isRetryable: false,
          statusCode: 404,
          backendCode: 'place_not_found',
        ),
        const NetworkFailure(
          code: 'network_timeout',
          kind: NetworkFailureKind.timeout,
          isRetryable: true,
        ),
      ]) {
        executor.failure = failure;

        final result = await load();

        expect(
          (result as FailureResult<DestinationDetail>).failure,
          same(failure),
        );
      }
      expect(executor.calls, 2);
      expect(source.detailCalls, 0);
    });

    test('maps malformed responses without retrying', () async {
      source.error = const FormatException('bad response');

      expectFailure(await load(), DestinationDetailFailureKind.invalidResponse);
      expect(source.detailCalls, 1);
      expect(executor.calls, 1);
    });

    test('does not disguise unexpected programming errors', () async {
      final error = StateError('bug');
      source.error = error;

      await expectLater(load(), throwsA(same(error)));
    });
  });

  group('getDestinationPlaceDetail', () {
    Future<Result<DestinationPlaceDetail>> load({
      String destinationSlug = 'tokyo-japan',
      String placeSlug = 'meiji-shrine',
    }) {
      return repository.getDestinationPlaceDetail(
        destinationSlug: destinationSlug,
        placeSlug: placeSlug,
      );
    }

    void expectFailure(
      Result<DestinationPlaceDetail> result,
      DestinationPlaceDetailFailureKind kind,
    ) {
      expect(result, isA<FailureResult<DestinationPlaceDetail>>());
      final failure = (result as FailureResult<DestinationPlaceDetail>).failure;
      expect(failure, isA<DestinationPlaceDetailFailure>());
      expect((failure as DestinationPlaceDetailFailure).kind, kind);
    }

    test('normalizes both slugs and returns the matching detail', () async {
      final result = await load(
        destinationSlug: '  tokyo-japan  ',
        placeSlug: '  meiji-shrine  ',
      );

      expect(
        (result as Success<DestinationPlaceDetail>).value,
        same(source.placeDetailResponse.toDomain()),
      );
      expect(source.placeDestinationSlug, 'tokyo-japan');
      expect(source.placeSlug, 'meiji-shrine');
      expect(source.placeDetailCalls, 1);
      expect(executor.calls, 1);
    });

    test('invalid destination slug avoids executor and remote work', () async {
      for (final slug in ['', '   ', 'Tokyo Japan', '../tokyo']) {
        expectFailure(
          await load(destinationSlug: slug),
          DestinationPlaceDetailFailureKind.invalidDestinationSlug,
        );
      }

      expect(executor.calls, 0);
      expect(source.placeDetailCalls, 0);
    });

    test('invalid place slug avoids executor and remote work', () async {
      for (final slug in ['', '   ', 'Meiji Shrine', '../meiji']) {
        expectFailure(
          await load(placeSlug: slug),
          DestinationPlaceDetailFailureKind.invalidPlaceSlug,
        );
      }

      expect(executor.calls, 0);
      expect(source.placeDetailCalls, 0);
    });

    test('maps both documented not-found responses', () async {
      for (final backendCode in [
        'destination_not_found',
        'destination_place_not_found',
      ]) {
        executor.failure = NetworkFailure(
          code: 'not_found',
          kind: NetworkFailureKind.notFound,
          isRetryable: false,
          statusCode: 404,
          backendCode: backendCode,
        );

        expectFailure(await load(), DestinationPlaceDetailFailureKind.notFound);
      }

      expect(executor.calls, 2);
      expect(source.placeDetailCalls, 0);
    });

    test('preserves unrelated network failures unchanged', () async {
      for (final failure in [
        const NetworkFailure(
          code: 'not_found',
          kind: NetworkFailureKind.notFound,
          isRetryable: false,
          statusCode: 404,
          backendCode: 'place_not_found',
        ),
        const NetworkFailure(
          code: 'network_timeout',
          kind: NetworkFailureKind.timeout,
          isRetryable: true,
        ),
      ]) {
        executor.failure = failure;

        final result = await load();

        expect(
          (result as FailureResult<DestinationPlaceDetail>).failure,
          same(failure),
        );
      }

      expect(executor.calls, 2);
      expect(source.placeDetailCalls, 0);
    });

    test('maps malformed responses to an invalid-response failure', () async {
      source.error = const FormatException('bad response');

      expectFailure(
        await load(),
        DestinationPlaceDetailFailureKind.invalidResponse,
      );
      expect(source.placeDetailCalls, 1);
      expect(executor.calls, 1);
    });

    test(
      'rejects a response whose destination identity does not match',
      () async {
        source.placeDetailResponse = _placeDetailResponse(
          destinationSlug: 'kyoto-japan',
        );

        expectFailure(
          await load(),
          DestinationPlaceDetailFailureKind.invalidResponse,
        );
        expect(source.placeDetailCalls, 1);
        expect(executor.calls, 1);
      },
    );

    test('rejects a response whose place identity does not match', () async {
      source.placeDetailResponse = _placeDetailResponse(placeSlug: 'senso-ji');

      expectFailure(
        await load(),
        DestinationPlaceDetailFailureKind.invalidResponse,
      );
      expect(source.placeDetailCalls, 1);
      expect(executor.calls, 1);
    });

    test('does not disguise unexpected programming errors', () async {
      final error = StateError('bug');
      source.error = error;

      await expectLater(load(), throwsA(same(error)));
    });
  });

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
