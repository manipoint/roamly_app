import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/destination_place_detail.dart';
import '../../domain/repositories/home_discovery_repository.dart';
import '../policies/home_cache_policy.dart';
import 'retryable_detail_controller.dart';

typedef DestinationPlaceDetailRequest = ({
  String destinationSlug,
  String placeSlug,
});

final destinationPlaceDetailControllerProvider = AsyncNotifierProvider
    .autoDispose
    .family<
      DestinationPlaceDetailController,
      DestinationPlaceDetail,
      DestinationPlaceDetailRequest
    >(DestinationPlaceDetailController.new, retry: (_, _) => null);

final class DestinationPlaceDetailController
    extends RetryableDetailController<DestinationPlaceDetail> {
  DestinationPlaceDetailController(this.request);

  final DestinationPlaceDetailRequest request;

  @override
  Duration get cacheDuration => HomeCachePolicy.destinationPlaceDetail;

  @override
  Future<DestinationPlaceDetail> fetch(
    HomeDiscoveryRepository repository,
  ) async {
    final result = await repository.getDestinationPlaceDetail(
      destinationSlug: request.destinationSlug,
      placeSlug: request.placeSlug,
    );
    return result.fold(
      onSuccess: (success) => success,
      onFailure: (failure) => throw failure,
    );
  }
}
