import 'package:roamly_app/src/features/home/data/models/destination_model.dart'
    show DestinationModel;
import 'package:roamly_networking/roamly_networking.dart';

import '../../domain/entities/destination.dart';
import '../../domain/entities/destination_collection.dart';
import '../mappers/home_discovery_enum_mapper.dart';

/// Parses the backend's bounded spotlight collection.
final class DestinationCollectionModel {
  const DestinationCollectionModel._(this._collection);

  final DestinationCollection _collection;

  factory DestinationCollectionModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);

    return DestinationCollectionModel._(
      DestinationCollection(
        kind: HomeDiscoveryEnumMapper.collectionKindFromJson(
          reader.string('kind'),
        ),
        items: reader.list<Destination>(
          'items',
          maxLength: 6,
          unique: true,
          parseItem: (value) {
            return DestinationModel.fromValue(value).toDomain();
          },
        ),
      ),
    );
  }

  DestinationCollection toDomain() => _collection;
}
