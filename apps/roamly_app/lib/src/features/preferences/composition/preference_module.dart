import 'package:roamly_app/src/features/preferences/data/repositories/default_location_resolution_repository.dart';
import 'package:roamly_app/src/features/preferences/data/repositories/default_preference_repository.dart';
import 'package:roamly_app/src/features/preferences/data/sources/api_location_resolution_remote_data_source.dart';
import 'package:roamly_app/src/features/preferences/data/sources/api_preference_remote_data_source.dart';
import 'package:roamly_app/src/features/preferences/domain/repositories/location_resolution_repository.dart';
import 'package:roamly_app/src/features/preferences/domain/repositories/preference_repository.dart';
import 'package:roamly_networking/roamly_networking.dart';

abstract final class PreferenceModule {
  static PreferenceRepository create({
    required ApiClient authenticatedClient,
    required ApiRequestExecutor requestExecutor,
  }) {
    final remoteDataSource = ApiPreferenceRemoteDataSource(
      authenticatedClient: authenticatedClient,
    );
    return DefaultPreferenceRepository(
      remoteDataSource: remoteDataSource,
      requestExecutor: requestExecutor,
    );
  }

  static LocationResolutionRepository createLocationResolutionRepository({
    required ApiClient authenticatedClient,
    required ApiRequestExecutor requestExecutor,
  }) {
    return DefaultLocationResolutionRepository(
      remoteDataSource: ApiLocationResolutionRemoteDataSource(
        apiClient: authenticatedClient,
      ),
      requestExecutor: requestExecutor,
    );
  }
}
