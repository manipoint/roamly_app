import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_networking/roamly_networking.dart';

import '../../domain/entities/canonical_location.dart';
import '../../domain/failures/location_resolution_failure.dart';
import '../../domain/policies/location_resolution_policy.dart';
import '../../domain/repositories/location_resolution_repository.dart';
import '../sources/location_resolution_remote_data_source.dart';

/// Validates search input and isolates transport models from presentation.
final class DefaultLocationResolutionRepository
    implements LocationResolutionRepository {
  const DefaultLocationResolutionRepository({
    required LocationResolutionRemoteDataSource remoteDataSource,
    required ApiRequestExecutor requestExecutor,
  }) : _remoteDataSource = remoteDataSource,
       _requestExecutor = requestExecutor;

  final LocationResolutionRemoteDataSource _remoteDataSource;
  final ApiRequestExecutor _requestExecutor;

  @override
  Future<Result<List<CanonicalLocation>>> resolve({
    required String query,
    int limit = LocationResolutionPolicy.maximumResultLimit,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < LocationResolutionPolicy.minimumQueryLength ||
        normalizedQuery.length > LocationResolutionPolicy.maximumQueryLength) {
      return const FailureResult<List<CanonicalLocation>>(
        LocationResolutionFailure.invalidQuery(),
      );
    }
    if (limit < 1 || limit > LocationResolutionPolicy.maximumResultLimit) {
      return const FailureResult<List<CanonicalLocation>>(
        LocationResolutionFailure.invalidLimit(),
      );
    }

    try {
      return await _requestExecutor.execute<List<CanonicalLocation>>(() async {
        final response = await _remoteDataSource.resolve(
          query: normalizedQuery,
          limit: limit,
        );
        return response.options;
      });
    } on FormatException {
      return const FailureResult<List<CanonicalLocation>>(
        LocationResolutionFailure.invalidResponse(),
      );
    }
  }
}
