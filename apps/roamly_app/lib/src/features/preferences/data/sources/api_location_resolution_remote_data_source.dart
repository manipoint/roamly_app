import 'package:roamly_networking/roamly_networking.dart';

import '../../domain/policies/location_resolution_policy.dart';
import '../api/location_resolution_api_paths.dart';
import '../models/location_resolution_response_model.dart';
import 'location_resolution_remote_data_source.dart';

final class ApiLocationResolutionRemoteDataSource
    implements LocationResolutionRemoteDataSource {
  const ApiLocationResolutionRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<LocationResolutionResponseModel> resolve({
    required String query,
    int limit = LocationResolutionPolicy.maximumResultLimit,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < LocationResolutionPolicy.minimumQueryLength ||
        normalizedQuery.length > LocationResolutionPolicy.maximumQueryLength) {
      throw ArgumentError.value(
        query,
        'query',
        'Must contain between 2 and 120 characters after trimming.',
      );
    }
    if (limit < 1 || limit > LocationResolutionPolicy.maximumResultLimit) {
      throw RangeError.range(
        limit,
        1,
        LocationResolutionPolicy.maximumResultLimit,
        'limit',
      );
    }
    final response = await _apiClient.get(
      LocationResolutionApiPaths.resolve,
      queryParameters: {'query': normalizedQuery, 'limit': limit},
    );
    final reader = JsonReader(<String, Object?>{'response': response});
    final model = LocationResolutionResponseModel.fromJson(
      reader.object('response'),
    );

    if (model.query != normalizedQuery) {
      throw const FormatException(
        'Location resolution response query mismatch.',
      );
    }
    return model;
  }
}
