import 'package:roamly_app/src/features/home/data/api/home_api_paths.dart';
import 'package:roamly_app/src/features/home/data/models/home_discovery_model.dart';
import 'package:roamly_app/src/features/home/data/sources/home_remote_data_source.dart';
import 'package:roamly_networking/roamly_networking.dart';

import '../../domain/policies/home_discovery_policy.dart';

final class ApiHomeRemoteDataSource implements HomeRemoteDataSource {
  final ApiClient _apiClient;

  const ApiHomeRemoteDataSource({required ApiClient authenticatedClient})
    : _apiClient = authenticatedClient;

  @override
  Future<HomeDiscoveryModel> getHome({required int limit}) async {
    if (!HomeDiscoveryPolicy.isValidLimit(limit)) {
      throw RangeError.range(
        limit,
        HomeDiscoveryPolicy.minimumSectionLimit,
        HomeDiscoveryPolicy.maximumSectionLimit,
        'limit',
      );
    }
    final response = await _apiClient.get(
      HomeApiPaths.discovery,
      queryParameters: <String, Object?>{'limit': limit},
    );
    final reader = JsonReader(<String, Object?>{'response': response});
    return HomeDiscoveryModel.fromJson(reader.object('response'));
  }
}
