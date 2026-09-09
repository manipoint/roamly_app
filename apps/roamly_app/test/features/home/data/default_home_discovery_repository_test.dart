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
