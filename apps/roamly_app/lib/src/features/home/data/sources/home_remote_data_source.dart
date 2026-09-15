import 'package:roamly_app/src/features/home/data/models/destination_detail_model.dart';
import 'package:roamly_app/src/features/home/data/models/home_discovery_model.dart';

import '../../domain/entities/destination_collection_query.dart';
import '../models/destination_page_model.dart';
import '../models/destination_place_detail_model.dart';

abstract interface class HomeRemoteDataSource {
  Future<HomeDiscoveryModel> getHome({required int limit});
  Future<DestinationPageModel> getDestinations({
    required DestinationCollectionQuery query,
    required int limit,
    String? cursor,
  });
  Future<DestinationDetailModel> getDestinationDetail({required String slug});

  Future<DestinationPlaceDetailModel> getDestinationPlaceDetail({
    required String destinationSlug,
    required String placeSlug,
  });
}
