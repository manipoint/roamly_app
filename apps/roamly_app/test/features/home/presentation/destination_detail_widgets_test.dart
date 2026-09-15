import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/domain/entities/media_asset.dart';
import 'package:roamly_app/src/features/home/presentation/constants/home_layout.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/destination_about_section.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/destination_detail_body.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/destination_detail_error_view.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/destination_detail_loading_view.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/destination_detail_page_frame.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/destination_media_gallery.dart';
import 'package:roamly_app/src/features/home/presentation/widgets/destination_media_image.dart';
import 'package:roamly_ui/roamly_ui.dart';

MediaAsset _media(String id) {
  return MediaAsset(
    id: id,
    uri: Uri.parse('https://images.example.com/$id.jpg'),
    altText: 'Travel image $id',
    caption: null,
    width: 1600,
    height: 900,
  );
}

void main() {
  Future<void> pumpSubject(WidgetTester tester, Widget subject) {
    return tester.pumpWidget(
      MaterialApp(
        theme: RoamlyTheme.light,
        home: Scaffold(body: subject),
      ),
    );
  }

  testWidgets('detail body provides the shared landscape hero and content', (
    tester,
  ) async {
    final cover = _media('cover');

    await pumpSubject(
      tester,
      DestinationDetailBody(
        pageStorageKey: 'destination-bali',
        coverImage: cover,
        children: const [Text('Bali detail content')],
      ),
    );

    final heroAspectRatio = tester.widget<AspectRatio>(
      find.descendant(
        of: find.byType(DestinationDetailBody),
        matching: find.byType(AspectRatio),
      ),
    );
    final heroImage = tester.widget<DestinationMediaImage>(
      find.descendant(
        of: find.byType(DestinationDetailBody),
        matching: find.byType(DestinationMediaImage),
      ),
    );

    expect(heroAspectRatio.aspectRatio, HomeLayout.heroImageAspectRatio);
    expect(heroAspectRatio.aspectRatio, 1);
    expect(heroImage.media, cover);
    expect(heroImage.boxFit, BoxFit.cover);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pump();

    expect(find.text('Bali detail content'), findsOneWidget);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('detail body forwards cover image taps', (tester) async {
    var tapCount = 0;

    await pumpSubject(
      tester,
      DestinationDetailBody(
        pageStorageKey: 'destination-cover',
        coverImage: _media('cover'),
        onCoverTap: () => tapCount++,
        children: const [],
      ),
    );

    await tester.tap(find.byType(DestinationMediaImage));
    expect(tapCount, 1);
  });

  testWidgets('page frame keeps navigation above every detail state', (
    tester,
  ) async {
    var backCount = 0;

    await pumpSubject(
      tester,
      DestinationDetailPageFrame(
        onBack: () => backCount++,
        body: const Center(child: Text('Loading or error content')),
      ),
    );

    final scaffold = tester.widget<RoamlyScaffold>(find.byType(RoamlyScaffold));
    expect(scaffold.safeAreaTop, isFalse);
    expect(scaffold.bodyPadding, EdgeInsets.zero);
    expect(find.byType(IconButton), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    expect(backCount, 1);
  });

  testWidgets('about section renders its semantic heading and description', (
    tester,
  ) async {
    await pumpSubject(
      tester,
      const DestinationAboutSection(
        title: 'About this place',
        description: 'A quiet mountain destination.',
      ),
    );

    expect(find.text('About this place'), findsOneWidget);
    expect(find.text('A quiet mountain destination.'), findsOneWidget);

    final semantics = tester.getSemantics(find.text('About this place'));
    expect(semantics.flagsCollection.isHeader, isTrue);
  });

  testWidgets('loading view matches the landscape hero geometry', (
    tester,
  ) async {
    await pumpSubject(tester, const DestinationDetailLoadingView());

    final heroAspectRatio = tester.widget<AspectRatio>(
      find.descendant(
        of: find.byType(DestinationDetailLoadingView),
        matching: find.byType(AspectRatio),
      ),
    );

    expect(heroAspectRatio.aspectRatio, HomeLayout.heroImageAspectRatio);
    expect(find.byType(RoamlySkeleton), findsNWidgets(7));
  });

  testWidgets('media gallery renders landscape images with cover fit', (
    tester,
  ) async {
    await pumpSubject(
      tester,
      DestinationMediaGallery(
        title: 'Gallery',
        media: [_media('one'), _media('two')],
      ),
    );

    expect(find.text('Gallery'), findsOneWidget);
    expect(find.byType(DestinationMediaImage), findsNWidgets(2));

    final images = tester.widgetList<DestinationMediaImage>(
      find.byType(DestinationMediaImage),
    );
    expect(images.every((image) => image.boxFit == BoxFit.cover), isTrue);

    final ratios = tester.widgetList<AspectRatio>(find.byType(AspectRatio));
    expect(ratios.every((ratio) => ratio.aspectRatio == 16 / 9), isTrue);
  });

  testWidgets('media gallery forwards the selected media', (tester) async {
    MediaAsset? selected;
    final first = _media('one');

    await pumpSubject(
      tester,
      DestinationMediaGallery(
        title: 'Gallery',
        media: [first, _media('two')],
        onMediaTap: (media) => selected = media,
      ),
    );

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is DestinationMediaImage && widget.media?.id == 'one',
      ),
    );
    expect(selected, first);
  });

  testWidgets('media gallery renders nothing when no media is available', (
    tester,
  ) async {
    await pumpSubject(
      tester,
      const DestinationMediaGallery(title: 'Gallery', media: []),
    );

    expect(find.text('Gallery'), findsNothing);
    expect(find.byType(DestinationMediaImage), findsNothing);
  });

  testWidgets('error view only exposes retry when a callback is provided', (
    tester,
  ) async {
    var retryCount = 0;

    await pumpSubject(
      tester,
      DestinationDetailErrorView(
        message: 'Could not load place.',
        icon: Icons.place_outlined,
        onRetry: () async {
          retryCount++;
        },
      ),
    );

    expect(find.text('Could not load place.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(retryCount, 1);

    await pumpSubject(
      tester,
      const DestinationDetailErrorView(
        message: 'Place does not exist.',
        icon: Icons.place_outlined,
      ),
    );

    expect(find.text('Try again'), findsNothing);
  });
}
