import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';

import '../../../../localization/app_strings.dart';
import '../../domain/entities/map_location.dart';
import '../services/destination_map_launcher.dart';

final _launcher = DestinationMapLauncher();

Future<void> openDestinationMap(
  BuildContext context, {
  required String title,
  required MapLocation location,
  DestinationMapLauncher? launcher,
}) async {
  final result = await (launcher ?? _launcher).open(
    title: title,
    location: location,
    isActive: () => context.mounted,
    choose: (maps) => showModalBottomSheet<SupportedMap>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.chooseMapApp,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              for (final map in maps)
                ListTile(
                  title: Text(map.name),
                  leading: const Icon(Icons.map_outlined),
                  onTap: () => Navigator.of(sheetContext).pop(map),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  if (!context.mounted) return;
  final message = switch (result) {
    MapLaunchResult.unavailable => AppStrings.noMapAppAvailable,
    MapLaunchResult.failed => AppStrings.mapOpenFailed,
    _ => null,
  };
  if (message != null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
