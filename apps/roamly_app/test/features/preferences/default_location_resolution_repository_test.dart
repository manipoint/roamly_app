import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/data/models/location_resolution_response_model.dart';
import 'package:roamly_app/src/features/preferences/data/repositories/default_location_resolution_repository.dart';
import 'package:roamly_app/src/features/preferences/data/sources/location_resolution_remote_data_source.dart';
import 'package:roamly_app/src/features/preferences/domain/entities/canonical_location.dart';
import 'package:roamly_app/src/features/preferences/domain/failures/location_resolution_failure.dart';
import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_networking/roamly_networking.dart';

LocationResolutionResponseModel _response({String query = 'Lahore'}) {
  return LocationResolutionResponseModel.fromJson(<String, Object?>{
    'query': query,
    'options': <Object?>[
      <String, Object?>{
        'provider': 'google',
        'provider_location_id': 'lahore-id',
        'canonical_name': 'Lahore, Punjab, Pakistan',
        'country_code': 'PK',
        'latitude': 31.5204,
        'longitude': 74.3587,
      },
    ],
  });
}

final class _Source implements LocationResolutionRemoteDataSource {
  int calls = 0;
  String? query;
  int? limit;
  Object? error;
  LocationResolutionResponseModel response = _response();

  @override
  Future<LocationResolutionResponseModel> resolve({
    required String query,
    int limit = 5,
  }) async {
    calls++;
    this.query = query;
    this.limit = limit;
    if (error case final value?) throw value;
    return response;
  }
}

final class _Executor implements ApiRequestExecutor {
  int calls = 0;
  AppFailure? failure;

  @override
  Future<Result<T>> execute<T>(Future<T> Function() request) async {
    calls++;
    if (failure case final value?) return FailureResult<T>(value);
    return Success<T>(await request());
  }
}

void main() {
  late _Source source;
  late _Executor executor;
  late DefaultLocationResolutionRepository repository;

  setUp(() {
    source = _Source();
    executor = _Executor();
    repository = DefaultLocationResolutionRepository(
      remoteDataSource: source,
      requestExecutor: executor,
    );
  });

  void expectLocationFailure(
    Result<List<CanonicalLocation>> result,
    LocationResolutionFailureKind kind,
  ) {
    final failure = (result as FailureResult<List<CanonicalLocation>>).failure;
    expect(failure, isA<LocationResolutionFailure>());
    expect((failure as LocationResolutionFailure).kind, kind);
  }

  test('normalizes query and forwards the requested limit', () async {
    final result = await repository.resolve(query: '  Lahore  ', limit: 3);

    expect(executor.calls, 1);
    expect(source.calls, 1);
    expect(source.query, 'Lahore');
    expect(source.limit, 3);
    final locations = (result as Success<List<CanonicalLocation>>).value;
    expect(locations.single.canonicalName, 'Lahore, Punjab, Pakistan');
  });

  test('uses the backend maximum as the default result limit', () async {
    await repository.resolve(query: 'Lahore');

    expect(source.limit, 5);
  });

  test('invalid queries avoid executor and network work', () async {
    for (final query in <String>[
      '',
      ' ',
      'L',
      List<String>.filled(121, 'x').join(),
    ]) {
      expectLocationFailure(
        await repository.resolve(query: query),
        LocationResolutionFailureKind.invalidQuery,
      );
    }

    expect(executor.calls, 0);
    expect(source.calls, 0);
  });

  test('invalid limits avoid executor and network work', () async {
    for (final limit in <int>[0, 6]) {
      expectLocationFailure(
        await repository.resolve(query: 'Lahore', limit: limit),
        LocationResolutionFailureKind.invalidLimit,
      );
    }

    expect(executor.calls, 0);
    expect(source.calls, 0);
  });

  test('malformed responses become safe feature failures', () async {
    source.error = const FormatException('malformed response');

    expectLocationFailure(
      await repository.resolve(query: 'Lahore'),
      LocationResolutionFailureKind.invalidResponse,
    );
  });

  test('executor failures are preserved unchanged', () async {
    const failure = NetworkFailure(
      code: 'request_timeout',
      isRetryable: true,
      kind: NetworkFailureKind.timeout,
    );
    executor.failure = failure;

    final result = await repository.resolve(query: 'Lahore');

    expect((result as FailureResult<List<CanonicalLocation>>).failure, failure);
    expect(source.calls, 0);
  });

  test('programming errors are not disguised as expected failures', () async {
    final error = StateError('bug');
    source.error = error;

    await expectLater(
      repository.resolve(query: 'Lahore'),
      throwsA(same(error)),
    );
  });
}
