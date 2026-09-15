import 'package:roamly_app/src/features/home/domain/entities/destination_collection_query.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_detail.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_page.dart';
import 'package:roamly_app/src/features/home/domain/entities/destination_place_detail.dart';
import 'package:roamly_app/src/features/home/domain/failures/destination_place_detail_failure.dart';
import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_networking/roamly_networking.dart';

import '../../../../app/validator/roamly_value_validators.dart';
import '../../domain/entities/home_discovery.dart';
import '../../domain/failures/destination_catalogue_failure.dart';
import '../../domain/failures/destination_detail_failure.dart';
import '../../domain/failures/home_discovery_failure.dart';
import '../../domain/policies/home_discovery_policy.dart';
import '../../domain/repositories/home_discovery_repository.dart';
import '../models/destination_detail_model.dart';
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

  @override
  Future<Result<DestinationDetail>> getDestinationDetail({
    required String slug,
  }) async {
    final normalizedSlug = slug.trim();
    if (!RoamlyValueValidators.isValidSlug(normalizedSlug)) {
      return const FailureResult<DestinationDetail>(
        DestinationDetailFailure.invalidSlug(),
      );
    }
    try {
      final result = await _requestExecutor.execute(() async {
        final DestinationDetailModel model = await _remoteDataSource
            .getDestinationDetail(slug: normalizedSlug);
        return model.toDomain();
      });
      if (result is FailureResult<DestinationDetail>) {
        final failure = result.failure;
        if (failure is NetworkFailure &&
            failure.statusCode == 404 &&
            failure.backendCode == 'destination_not_found') {
          return const FailureResult<DestinationDetail>(
            DestinationDetailFailure.notFound(),
          );
        }
      }
      return result;
    } on FormatException {
      return const FailureResult<DestinationDetail>(
        DestinationDetailFailure.invalidResponse(),
      );
    }
  }

  @override
  Future<Result<DestinationPlaceDetail>> getDestinationPlaceDetail({
    required String destinationSlug,
    required String placeSlug,
  }) async {
    final normalizedDestinationSlug = destinationSlug.trim();
    final normalizedPlaceSlug = placeSlug.trim();

    if (!RoamlyValueValidators.isValidSlug(normalizedDestinationSlug)) {
      return const FailureResult<DestinationPlaceDetail>(
        DestinationPlaceDetailFailure.invalidDestinationSlug(),
      );
    }

    if (!RoamlyValueValidators.isValidSlug(normalizedPlaceSlug)) {
      return const FailureResult<DestinationPlaceDetail>(
        DestinationPlaceDetailFailure.invalidPlaceSlug(),
      );
    }

    try {
      final result = await _requestExecutor.execute<DestinationPlaceDetail>(
        () async {
          final model = await _remoteDataSource.getDestinationPlaceDetail(
            destinationSlug: normalizedDestinationSlug,
            placeSlug: normalizedPlaceSlug,
          );

          final detail = model.toDomain();

          _validatePlaceIdentity(
            detail: detail,
            expectedDestinationSlug: normalizedDestinationSlug,
            expectedPlaceSlug: normalizedPlaceSlug,
          );

          return detail;
        },
      );

      if (result is FailureResult<DestinationPlaceDetail>) {
        final failure = result.failure;

        if (_isPlaceNotFoundFailure(failure)) {
          return const FailureResult<DestinationPlaceDetail>(
            DestinationPlaceDetailFailure.notFound(),
          );
        }
      }

      return result;
    } on FormatException {
      return const FailureResult<DestinationPlaceDetail>(
        DestinationPlaceDetailFailure.invalidResponse(),
      );
    }
  }

  static bool _isPlaceNotFoundFailure(AppFailure failure) {
    if (failure is! NetworkFailure || failure.statusCode != 404) {
      return false;
    }

    return failure.backendCode == 'destination_not_found' ||
        failure.backendCode == 'destination_place_not_found';
  }

  static void _validatePlaceIdentity({
    required DestinationPlaceDetail detail,
    required String expectedDestinationSlug,
    required String expectedPlaceSlug,
  }) {
    if (detail.destinationSlug != expectedDestinationSlug ||
        detail.place.slug != expectedPlaceSlug) {
      throw const FormatException(
        'Destination place response identity does not match the request.',
      );
    }
  }
}
