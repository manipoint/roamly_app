import 'package:flutter/material.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_content_types.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_rich_content.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

import 'assistant_content_card.dart';

class AssistantHotelCardView extends StatelessWidget {
  const AssistantHotelCardView({super.key, required this.hotelCard});
  final AssistantHotelCard hotelCard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;
    final image = hotelCard.image;
    final category = hotelCard.category;
    final rating = hotelCard.rating;
    final reviewScore = hotelCard.reviewScore;
    final price = hotelCard.price;
    return AssistantContentCard(
      title: hotelCard.name,
      subtitle: hotelCard.location,
      image: image,
      details: [
        if (category != null) ...[
          RoamlyGap.h8,
          Text(
            category,
            style: textTheme.labelMedium?.copyWith(color: colors.primary),
          ),
        ],
        if (rating != null) ...[
          RoamlyGap.h8,
          Text(
            AppStrings.assistantHotelStars(rating),
            style: textTheme.bodySmall,
          ),
        ],
        if (reviewScore != null) ...[
          RoamlyGap.h4,
          Text(
            AppStrings.assistantHotelReviewScore(_formatScore(reviewScore)),
            style: textTheme.bodySmall,
          ),
        ],
        if (price != null) ...[
          RoamlyGap.h12,
          Text(
            AppStrings.assistantHotelQuotedPrice,
            style: textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          RoamlyGap.h4,
          Text(_formatPrice(price), style: textTheme.labelLarge),
        ],
      ],
    );
  }

  static String _formatScore(double score) {
    return score == score.truncateToDouble()
        ? score.toStringAsFixed(0)
        : score.toString();
  }

  static String _formatPrice(AssistantMoney price) {
    final amount = '${price.currency} ${price.amount}';

    return switch (price.qualifier) {
      AssistantMoneyQualifier.total =>
        '$amount ${AppStrings.assistantHotelTotal}',
      AssistantMoneyQualifier.perNight =>
        '$amount ${AppStrings.assistantHotelPerNight}',
      AssistantMoneyQualifier.from =>
        '${AppStrings.assistantHotelFrom} $amount',
    };
  }
}
