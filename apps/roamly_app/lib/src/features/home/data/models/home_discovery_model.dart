import 'package:roamly_networking/roamly_networking.dart';

import '../../domain/entities/destination.dart';
import '../../domain/entities/home_discovery.dart';
import 'destination_collection_model.dart';
import 'destination_model.dart';

/// Parses the complete Phase-1 Home discovery response.
final class HomeDiscoveryModel {
  const HomeDiscoveryModel._(this._discovery);

  final HomeDiscovery _discovery;

  factory HomeDiscoveryModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);

    return HomeDiscoveryModel._(
      HomeDiscovery(
        personalizationReady: reader.boolean('personalization_ready'),
        suggested: _readDestinations(reader, 'suggested'),
        popular: _readDestinations(reader, 'popular'),
        spotlight: DestinationCollectionModel.fromJson(
          reader.object('spotlight'),
        ).toDomain(),
      ),
    );
  }

  HomeDiscovery toDomain() => _discovery;

  static List<Destination> _readDestinations(JsonReader reader, String key) {
    return reader.list<Destination>(
      key,
      maxLength: 6,
      unique: true,
      parseItem: (value) {
        return DestinationModel.fromValue(value).toDomain();
      },
    );
  }
}
