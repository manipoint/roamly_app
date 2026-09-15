import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/domain/entities/media_asset.dart';
import 'package:roamly_app/src/features/home/presentation/pages/destination_media_viewer_page.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/destination_media_image.dart';

MediaAsset _media(String id) {
  return MediaAsset(
    id: id,
    uri: Uri.parse('https://images.example.com/$id.jpg'),
    altText: 'Image $id',
    caption: null,
    width: 1600,
    height: 900,
  );
}

void main() {
  testWidgets('starts on selected media and swipes through the collection', (
    tester,
  ) async {
    final media = [_media('one'), _media('two'), _media('three')];

    await tester.pumpWidget(
      MaterialApp(
        home: DestinationMediaViewerPage(
          title: 'Bali',
          media: media,
          initialIndex: 1,
        ),
      ),
    );

    expect(find.text('Bali'), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);

    final selectedImage = tester.widget<DestinationMediaImage>(
      find.byWidgetPredicate(
        (widget) =>
            widget is DestinationMediaImage && widget.media?.id == 'two',
      ),
    );
    expect(selectedImage.boxFit, BoxFit.contain);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('3 / 3'), findsOneWidget);
  });

  testWidgets('close button dismisses the viewer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => DestinationMediaViewerPage(
                        title: 'Hunza',
                        media: [_media('one')],
                        initialIndex: 0,
                      ),
                    ),
                  );
                },
                child: const Text('Open viewer'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open viewer'));
    await tester.pumpAndSettle();
    expect(find.byType(DestinationMediaViewerPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(DestinationMediaViewerPage), findsNothing);
  });
}
