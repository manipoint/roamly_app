import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/branding/roamly_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RoamlyAssets', () {
    test('contains unique asset paths', () {
      expect(RoamlyAssets.all.toSet(), hasLength(RoamlyAssets.all.length));
    });

    for (final assetPath in RoamlyAssets.all) {
      test('loads $assetPath from the Flutter asset bundle', () async {
        final asset = await rootBundle.load(assetPath);

        expect(asset.lengthInBytes, greaterThan(0));
      });
    }
  });
}
