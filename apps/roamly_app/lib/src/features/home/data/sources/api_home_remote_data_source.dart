import 'package:roamly_app/src/features/home/data/api/home_api_paths.dart';
import 'package:roamly_app/src/features/home/data/models/destination_detail_model.dart';
import 'package:roamly_app/src/features/home/data/models/destination_page_model.dart';
import 'package:roamly_app/src/features/home/data/models/home_discovery_model.dart';
import 'package:roamly_app/src/features/home/data/sources/home_remote_data_source.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_collection_query.dart';
import 'package:roamly_app/src/features/preferences/data/mappers/preference_enum_mapper.dart';
import 'package:roamly_networking/roamly_networking.dart';

import '../../../../app/validator/roamly_value_validators.dart';
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

  @override
  Future<DestinationPageModel> getDestinations({
    required DestinationCollectionQuery query,
    required int limit,
    String? cursor,
  }) async {
    if (limit < 1 || limit > 50) {
      throw RangeError.range(limit, 1, 50, 'limit');
    }
    if (cursor != null && (cursor.isEmpty || cursor.length > 512)) {
      throw ArgumentError('Cursor must contain 1–512 characters.');
    }

    final scope = query.scope;
    final parameters = <String, Object?>{
      'collection': switch (query.collection) {
        DestinationCollectionType.popular => 'popular',
        DestinationCollectionType.featured => 'featured',
        DestinationCollectionType.suggested => 'suggested',
      },
      'limit': limit,
      if (scope != null)
        'scope': PreferenceEnumMapper.recommendationScopeToJson(scope),
      'cursor': ?cursor,
    };
    final response = await _apiClient.get(
      HomeApiPaths.destinations,
      queryParameters: parameters,
    );

    final reader = JsonReader(<String, Object?>{'response': response});

    return DestinationPageModel.fromJson(reader.object('response'));
  }

  @override
  Future<DestinationDetailModel> getDestinationDetail({
    required String slug,
  }) async {
    final normalizedSlug = slug.trim();
    if (!RoamlyValueValidators.isValidSlug(normalizedSlug)) {
      throw ArgumentError.value(slug, 'slug', 'Destination slug is invalid.');
    }

    final response = await _apiClient.get(HomeApiPaths.destinationDetail(normalizedSlug));
    final reader = JsonReader(<String, Object?>{'response': response});
    return DestinationDetailModel.fromJson(reader.object('response'));
  }
}
