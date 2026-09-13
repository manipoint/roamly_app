import 'package:roamly_networking/roamly_networking.dart';

import '../../domain/entities/map_location.dart';

final class MapLocationModel {
  const MapLocationModel._(this._location);

  final MapLocation _location;

  factory MapLocationModel.fromJson(
    Map<String, Object?> json, {
    bool requireMapZoom = false,
  }) {
    final reader = JsonReader(json);
    final mapZoom = reader.nullable<int>(
      'map_zoom',
      () => reader.integer('map_zoom', min: 1, max: 20),
    );
    if (requireMapZoom && mapZoom == null) {
      throw const FormatException('Destination map zoom is required.');
    }
    return MapLocationModel._(
      MapLocation(
        latitude: reader.number('latitude', min: -90, max: 90),
        longitude: reader.number('longitude', min: -180, max: 180),
        mapZoom: mapZoom,
      ),
    );
  }

  MapLocation toDomain() => _location;
}
