import 'package:flutter/material.dart';
import 'package:roamly_app/src/features/assistant/presentation/widgets/assistant_itinerary_preview_view.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../domain/entities/assistant_message.dart';
import '../../domain/entities/assistant_rich_content.dart';
import 'assistant_content_carousel.dart';
import 'assistant_hotel_card_view.dart';
import 'assistant_message_bubble.dart';
import 'assistant_place_card_view.dart';

final class AssistantMessageTile extends StatelessWidget {
  const AssistantMessageTile({
    super.key,
    required this.message,
    this.onPlaceTap,
  });

  final AssistantMessage message;
  final ValueChanged<AssistantPlaceCard>? onPlaceTap;

  @override
  Widget build(BuildContext context) {
    final bubble = AssistantMessageBubble(message: message);

    if (message.author != AssistantMessageAuthor.assistant) {
      return bubble;
    }

    final sections =
        message.richContent?.sections
            .where(_isRenderable)
            .toList(growable: false) ??
        const <AssistantContentSection>[];

    if (sections.isEmpty) return bubble;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        bubble,
        for (final section in sections) ...[
          RoamlyGap.h12,
          _buildSection(section),
        ],
      ],
    );
  }

  static bool _isRenderable(AssistantContentSection section) {
    return switch (section) {
      AssistantPlaceCarousel value => value.items.isNotEmpty,
      AssistantHotelCarousel value => value.items.isNotEmpty,
      AssistantItineraryPreview() => true,
    };
  }

  Widget _buildSection(AssistantContentSection section) {
    return switch (section) {
      AssistantPlaceCarousel value => AssistantContentCarousel(
        title: value.title,
        itemCount: value.items.length,
        itemBuilder: (context, index) {
          final place = value.items[index];
          final onTap = onPlaceTap;
          return AssistantPlaceCardView(
            placeCard: place,
            onTap: onTap == null ? null : () => onTap(place),
          );
        },
      ),
      AssistantHotelCarousel value => AssistantContentCarousel(
        title: value.title,
        itemCount: value.items.length,
        itemBuilder: (context, index) =>
            AssistantHotelCardView(hotelCard: value.items[index]),
      ),
      AssistantItineraryPreview() => AssistantItineraryPreviewView(preview: section),
    };
  }
}
