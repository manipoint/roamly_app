import 'package:roamly_app/src/features/home/data/models/home_discovery_model.dart';

abstract interface class HomeRemoteDataSource {
  Future<HomeDiscoveryModel> getHome({required int limit});
}
