import 'package:flutter/material.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../domain/entities/assistant_rich_content.dart';
import 'assistant_content_card.dart';

final class AssistantPlaceCardView extends StatelessWidget {
  const AssistantPlaceCardView({
    super.key,
    required this.placeCard,
    this.onTap,
  });

  final AssistantPlaceCard placeCard;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = placeCard.subtitle;
    return AssistantContentCard(
      title: placeCard.name,
      subtitle: placeCard.location,
      image: placeCard.image,
      onTap: onTap,
      details: [
        if (subtitle != null) ...[
          RoamlyGap.h8,
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
