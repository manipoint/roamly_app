import 'package:roamly_app/src/features/home/domain/entities/destination_collection_query.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_page.dart';
import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_networking/roamly_networking.dart';

import '../../domain/entities/home_discovery.dart';
import '../../domain/failures/destination_catalogue_failure.dart';
import '../../domain/failures/home_discovery_failure.dart';
import '../../domain/policies/home_discovery_policy.dart';
import '../../domain/repositories/home_discovery_repository.dart';
import '../models/home_discovery_model.dart';
import '../sources/home_remote_data_source.dart';

/// Converts Home transport/parsing outcomes into safe application results.
///
/// It does not reorder, retry, cache, or call external providers.
final class DefaultHomeDiscoveryRepository implements HomeDiscoveryRepository {
 const DefaultHomeDiscoveryRepository({
    required HomeRemoteDataSource remoteDataSource,
    required ApiRequestExecutor requestExecutor,
  }) : _remoteDataSource = remoteDataSource,
       _requestExecutor = requestExecutor;

  final HomeRemoteDataSource _remoteDataSource;
  final ApiRequestExecutor _requestExecutor;



  @override
  Future<Result<HomeDiscovery>> getHome({required int limit}) {
    if (!HomeDiscoveryPolicy.isValidLimit(limit)) {
      return Future<Result<HomeDiscovery>>.value(
        const FailureResult<HomeDiscovery>(HomeDiscoveryFailure.invalidLimit()),
      );
    }

    return _execute(limit);
  }

  Future<Result<HomeDiscovery>> _execute(int limit) async {
    try {
      return await _requestExecutor.execute<HomeDiscovery>(() async {
        final HomeDiscoveryModel model = await _remoteDataSource.getHome(
          limit: limit,
        );
        return model.toDomain();
      });
    } on FormatException {
      return const FailureResult<HomeDiscovery>(
        HomeDiscoveryFailure.invalidResponse(),
      );
    }
  }

  @override
  Future<Result<DestinationPage>> getDestinations({
    required DestinationCollectionQuery query,
    int limit = 20,
    String? cursor,
  }) async {
    if (limit < 1 || limit > 50) {
      return const FailureResult<DestinationPage>(
        DestinationCatalogueFailure.invalidLimit(),
      );
    }
    if (cursor != null && (cursor.isEmpty || cursor.length > 512)) {
      return const FailureResult<DestinationPage>(
        DestinationCatalogueFailure.invalidCursor(),
      );
    }
    try {
      final result = await _requestExecutor.execute(() async {
        final model = await _remoteDataSource.getDestinations(
          query: query,
          limit: limit,
          cursor: cursor,
        );
    
        return model.toDomain();
      });
      if (result is FailureResult<DestinationPage>) {
        final failure = result.failure;

        if (failure is NetworkFailure &&
            failure.statusCode == 422 &&
            failure.backendCode == 'invalid_cursor') {
          return const FailureResult<DestinationPage>(
            DestinationCatalogueFailure.invalidCursor(),
          );
        }
      }

      return result;
    } on FormatException {
      return const FailureResult<DestinationPage>(
        DestinationCatalogueFailure.invalidResponse(),
      );
    }
  }
}
