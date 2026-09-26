import 'package:flutter/material.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_content_types.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_rich_content.dart';
import 'package:roamly_app/src/features/assistant/presentation/constants/assistant_layout.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

class AssistantItineraryPreviewView extends StatelessWidget {
  const AssistantItineraryPreviewView({
    super.key,
    required this.preview,
    this.onViewItinerary,
  });
  final AssistantItineraryPreview preview;
  final ValueChanged<String>? onViewItinerary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final summary = preview.summary;
    final cover = summary.coverImage;
    final travelerCount = summary.travelerCount;
    final pace = summary.pace;
    final onView = onViewItinerary;
    final dateRange =
        '${localizations.formatMediumDate(summary.startDate)}'
        '-'
        '${localizations.formatMediumDate(summary.endDate)}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(preview.title, style: theme.textTheme.titleSmall),
        ),
        RoamlyGap.h8,
        Material(
          color: colors.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: RoamlyRadii.medium,
            side: BorderSide(color: colors.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (cover != null)
                AspectRatio(
                  aspectRatio: AssistantLayout.itineraryCoverAspectRatio,
                  child: RoamlyNetworkImage(
                    uri: cover.uri,
                    fit: BoxFit.cover,
                    altText: cover.altText,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(RoamlySpacing.space12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(summary.title, style: theme.textTheme.titleMedium),
                    RoamlyGap.h4,
                    Text(
                      dateRange,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    RoamlyGap.h8,
                    Wrap(
                      spacing: RoamlySpacing.space12,
                      runSpacing: RoamlySpacing.space4,
                      children: [
                        Text(
                          AppStrings.assistantTripDays(summary.durationDays),
                          style: theme.textTheme.labelMedium,
                        ),
                        if (travelerCount != null)
                          Text(
                            AppStrings.assistantTripTravelers(travelerCount),
                            style: theme.textTheme.labelMedium,
                          ),
                        if (pace != null)
                          Text(
                            _paceLabel(pace),
                            style: theme.textTheme.labelMedium,
                          ),
                      ],
                    ),
                    if (summary.cities.isNotEmpty) ...[
                      RoamlyGap.h8,
                      Text(
                        summary.cities.join(' • '),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    for (final day in preview.days) ...[
                      RoamlyGap.h12,
                      _ItineraryDayPreview(day: day),
                    ],
                    if (onView != null) ...[
                      RoamlyGap.h12,
                      RoamlyButton.destructive(
                        onPressed: () => onView(preview.itineraryId),
                        leadingIcon: const Icon(Icons.route_outlined),
                        label: AppStrings.assistantViewItinerary,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _paceLabel(AssistantItineraryPace pace) {
    return switch (pace) {
      AssistantItineraryPace.relaxed => AppStrings.assistantPaceRelaxed,
      AssistantItineraryPace.balanced => AppStrings.assistantPaceBalanced,
      AssistantItineraryPace.packed => AppStrings.assistantPacePacked,
    };
  }
}

class _ItineraryDayPreview extends StatelessWidget {
  const _ItineraryDayPreview({required this.day});
  final AssistantItineraryDayPreview day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = day.subtitle;
    final date = MaterialLocalizations.of(context).formatMediumDate(day.date);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppStrings.assistantItineraryDay(day.dayNumber)}'
          ' • $date',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        RoamlyGap.h4,
        Text(day.title, style: theme.textTheme.bodyMedium),
        if (subtitle != null) ...[
          RoamlyGap.h4,
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
