import 'package:roamly_app/src/features/home/data/repositories/default_home_discovery_repository.dart';
import 'package:roamly_app/src/features/home/data/sources/api_home_remote_data_source.dart';
import 'package:roamly_app/src/features/home/domain/repositories/home_discovery_repository.dart';
import 'package:roamly_networking/roamly_networking.dart';

abstract final class HomeModule {
  static HomeDiscoveryRepository create({
    required ApiClient authenticatedClient,
    required ApiRequestExecutor requestExecutor,
  }) {
    return DefaultHomeDiscoveryRepository(
      remoteDataSource: ApiHomeRemoteDataSource(
        authenticatedClient: authenticatedClient,
      ),
      requestExecutor: requestExecutor,
    );
  }
}
