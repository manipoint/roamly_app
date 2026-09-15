import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/destination_detail.dart';
import '../../domain/repositories/home_discovery_repository.dart';
import '../policies/home_cache_policy.dart';
import 'retryable_detail_controller.dart';

final destinationDetailControllerProvider = AsyncNotifierProvider.autoDispose
    .family<DestinationDetailController, DestinationDetail, String>(
      DestinationDetailController.new,
      retry: (_, _) => null,
    );

final class DestinationDetailController
    extends RetryableDetailController<DestinationDetail> {
  DestinationDetailController(this.slug);

  final String slug;

  @override
  Duration get cacheDuration => HomeCachePolicy.destinationDetail;

  @override
  Future<DestinationDetail> fetch(HomeDiscoveryRepository repository) async {
    final result = await repository.getDestinationDetail(slug: slug);

    return result.fold(
      onSuccess: (detail) => detail,
      onFailure: (failure) => throw failure,
    );
  }
}
