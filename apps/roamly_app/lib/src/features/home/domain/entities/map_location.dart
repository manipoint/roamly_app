final class MapLocation {
  const MapLocation({
    required this.latitude,
    required this.longitude,
    this.mapZoom,
  });

  final double latitude;
  final double longitude;
  final int? mapZoom;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapLocation &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          mapZoom == other.mapZoom;

  @override
  int get hashCode => Object.hash(latitude, longitude, mapZoom);
}
