import 'package:flutter/services.dart';
import 'package:map_launcher/map_launcher.dart';

import '../../domain/entities/map_location.dart';

enum MapLaunchResult { opened, cancelled, unavailable, failed, busy }

typedef DiscoverDestinationMaps =
    Future<List<SupportedMap>> Function(String title, MapLocation location);

/// Discovers native maps and coordinates a single launch at a time.
final class DestinationMapLauncher {
  DestinationMapLauncher({DiscoverDestinationMaps? discover})
    : _discover = discover ?? _installedMaps;

  final DiscoverDestinationMaps _discover;
  bool _busy = false;

  Future<MapLaunchResult> open({
    required String title,
    required MapLocation location,
    required bool Function() isActive,
    required Future<SupportedMap?> Function(List<SupportedMap>) choose,
  }) async {
    if (_busy) return MapLaunchResult.busy;
    _busy = true;
    try {
      final maps = await _discover(title, location);
      if (!isActive()) return MapLaunchResult.cancelled;
      if (maps.isEmpty) return MapLaunchResult.unavailable;
      final selected = maps.length == 1 ? maps.single : await choose(maps);
      if (selected == null || !isActive()) return MapLaunchResult.cancelled;
      await selected.show();
      return MapLaunchResult.opened;
    } on MapLaunchException {
      return MapLaunchResult.failed;
    } on PlatformException {
      return MapLaunchResult.failed;
    } on MissingPluginException {
      return MapLaunchResult.failed;
    } finally {
      _busy = false;
    }
  }

  static Future<List<SupportedMap>> _installedMaps(
    String title,
    MapLocation location,
  ) async {
    final request = MapLauncher.directions(
      Location.coords(location.latitude, location.longitude, title: title),
    );
    final maps = await request.getSupportedMaps(const [
      MapApp.apple,
      MapApp.google,
      MapApp.waze,
    ]);
    return maps.where((map) => map.isInstalled).toList(growable: false);
  }
}
