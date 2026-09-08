import '../../domain/policies/location_resolution_policy.dart';
import '../models/location_resolution_response_model.dart';

/// Retrieves provider-verified canonical location options.
abstract interface class LocationResolutionRemoteDataSource {
  /// Resolves normalized user-entered text into at most [limit] options.
  ///
  /// Transport and parsing errors propagate to the repository.
  Future<LocationResolutionResponseModel> resolve({
    required String query,
    int limit = LocationResolutionPolicy.maximumResultLimit,
  });
}
