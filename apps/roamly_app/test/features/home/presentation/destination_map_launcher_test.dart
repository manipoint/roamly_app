import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:roamly_app/src/features/home/domain/entities/map_location.dart';
import 'package:roamly_app/src/features/home/presentation/services/destination_map_launcher.dart';
import 'package:roamly_app/src/features/home/presentation/support/open_destination_map.dart';

void main() {
  const location = MapLocation(latitude: 35, longitude: 139);
  SupportedMap app(MapApp map, Future<void> Function() launch) =>
      SupportedMap.launchable(
        map: map,
        isInstalled: true,
        launcher: ({extra}) => launch(),
      );

  test('one app opens directly and receives exact destination', () async {
    var calls = 0;
    final launcher = DestinationMapLauncher(
      discover: (title, point) async {
        expect(title, 'Tokyo');
        expect(point, location);
        return [
          app(MapApp.google, () async {
            calls++;
          }),
        ];
      },
    );
    expect(
      await launcher.open(
        title: 'Tokyo',
        location: location,
        isActive: () => true,
        choose: (_) async => throw StateError('No chooser'),
      ),
      MapLaunchResult.opened,
    );
    expect(calls, 1);
  });

  test('no installed apps reports unavailable', () async {
    final launcher = DestinationMapLauncher(discover: (_, _) async => []);
    expect(
      await launcher.open(
        title: 'Tokyo',
        location: location,
        isActive: () => true,
        choose: (_) async => null,
      ),
      MapLaunchResult.unavailable,
    );
  });

  test('concurrent taps and disposed caller do not launch', () async {
    final pending = Completer<List<SupportedMap>>();
    var active = true;
    final launcher = DestinationMapLauncher(discover: (_, _) => pending.future);
    Future<MapLaunchResult> open() => launcher.open(
      title: 'Tokyo',
      location: location,
      isActive: () => active,
      choose: (_) async => null,
    );
    final first = open();
    expect(await open(), MapLaunchResult.busy);
    active = false;
    pending.complete([]);
    expect(await first, MapLaunchResult.cancelled);
  });

  test('platform failure is recoverable on next tap', () async {
    var fail = true;
    final launcher = DestinationMapLauncher(
      discover: (_, _) async {
        if (fail) throw PlatformException(code: 'failure');
        return [];
      },
    );
    Future<MapLaunchResult> open() => launcher.open(
      title: 'Tokyo',
      location: location,
      isActive: () => true,
      choose: (_) async => null,
    );
    expect(await open(), MapLaunchResult.failed);
    fail = false;
    expect(await open(), MapLaunchResult.unavailable);
  });

  testWidgets('chooser opens only selected app and supports cancellation', (
    tester,
  ) async {
    var googleCalls = 0;
    var wazeCalls = 0;
    final launcher = DestinationMapLauncher(
      discover: (_, _) async => [
        app(MapApp.google, () async {
          googleCalls++;
        }),
        app(MapApp.waze, () async {
          wazeCalls++;
        }),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => openDestinationMap(
                context,
                title: 'Tokyo',
                location: location,
                launcher: launcher,
              ),
              child: const Text('Open map'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open map'));
    await tester.pumpAndSettle();
    expect(find.text('Google Maps'), findsOneWidget);
    await tester.tap(find.text('Waze'));
    await tester.pumpAndSettle();
    expect(wazeCalls, 1);
    expect(googleCalls, 0);
    await tester.tap(find.text('Open map'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Waze'))).pop();
    await tester.pumpAndSettle();
    expect(wazeCalls, 1);
    expect(googleCalls, 0);
  });
}
