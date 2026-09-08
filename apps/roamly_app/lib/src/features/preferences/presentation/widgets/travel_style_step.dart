import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../../../branding/roamly_assets.dart';
import '../../domain/entities/preference_types.dart';
import '../controllers/preference_draft_controller.dart';
import '../controllers/preference_flow_controller.dart';
import '../controllers/saved_preferences_controller.dart';
import 'preference_step_scaffold.dart';

final class TravelStyleStep extends ConsumerWidget {
  const TravelStyleStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowStep = ref.watch(preferenceFlowControllerProvider);
    final draft = ref.watch(preferenceDraftControllerProvider);
    final savedPreferences = ref.watch(savedPreferencesControllerProvider);

    return PreferenceStepScaffold(
      currentStep: flowStep.index,
      stepCount: PreferenceFlowStep.values.length,
      title: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: AppStrings.travelStyleTitlePrefix),
            TextSpan(
              text: AppStrings.travelStyleTitleEmphasis,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
      description: AppStrings.travelStyleDescription,
      isContinueEnabled: draft.travelStyle != null,
      isSubmitting: savedPreferences.isLoading,
      onSkip: savedPreferences.isLoading
          ? null
          : () {
              unawaited(
                ref
                    .read(savedPreferencesControllerProvider.notifier)
                    .skipOnboarding(),
              );
            },
      onContinue: () {
        ref.read(preferenceFlowControllerProvider.notifier).next();
      },
      body: _TravelStyleGrid(
        selectedStyle: draft.travelStyle,
        onSelected: (style) {
          ref
              .read(preferenceDraftControllerProvider.notifier)
              .selectTravelStyle(style);
        },
      ),
    );
  }
}

final class _TravelStyleGrid extends StatelessWidget {
  const _TravelStyleGrid({
    required this.selectedStyle,
    required this.onSelected,
  });

  final TravelStyle? selectedStyle;
  final ValueChanged<TravelStyle> onSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columnCount = constraints.maxWidth >= 600 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: TravelStyle.values.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columnCount,
                crossAxisSpacing: RoamlySpacing.space12,
                mainAxisSpacing: RoamlySpacing.space12,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final style = TravelStyle.values[index];

                return _TravelStyleCard(
                  key: ValueKey<String>('travel-style-${style.name}'),
                  label: _labelFor(style),
                  image: _imageFor(style),
                  icon: _iconFor(style),
                  isSelected: selectedStyle == style,
                  onTap: () => onSelected(style),
                );
              },
            );
          },
        ),
      ),
    );
  }

  static String _labelFor(TravelStyle style) {
    return switch (style) {
      TravelStyle.beaches => AppStrings.travelStyleBeaches,
      TravelStyle.adventure => AppStrings.travelStyleAdventure,
      TravelStyle.food => AppStrings.travelStyleFood,
      TravelStyle.luxury => AppStrings.travelStyleLuxury,
      TravelStyle.nature => AppStrings.travelStyleNature,
      TravelStyle.culture => AppStrings.travelStyleCulture,
    };
  }

  static String _imageFor(TravelStyle style) {
    return switch (style) {
      TravelStyle.beaches => RoamlyAssets.beaches,
      TravelStyle.adventure => RoamlyAssets.advanture,
      TravelStyle.food => RoamlyAssets.food,
      TravelStyle.luxury => RoamlyAssets.luxury,
      TravelStyle.nature => RoamlyAssets.nature,
      TravelStyle.culture => RoamlyAssets.culture,
    };
  }

  static IconData _iconFor(TravelStyle style) {
    return switch (style) {
      TravelStyle.beaches => Icons.beach_access_outlined,
      TravelStyle.adventure => Icons.hiking_outlined,
      TravelStyle.food => Icons.restaurant_outlined,
      TravelStyle.luxury => Icons.diamond_outlined,
      TravelStyle.nature => Icons.forest_outlined,
      TravelStyle.culture => Icons.account_balance_outlined,
    };
  }
}

final class _TravelStyleCard extends StatelessWidget {
  const _TravelStyleCard({
    super.key,
    required this.label,
    required this.image,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String image;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderColor = isSelected ? colors.primary : colors.outlineVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: colors.surface,
        borderRadius: RoamlyRadii.large,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: RoamlyRadii.large,
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
              color: colors.surface,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Image.asset(
                        image,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        cacheWidth: 800,
                        filterQuality: FilterQuality.medium,
                        gaplessPlayback: true,
                        excludeFromSemantics: true,
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(minHeight: 24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: RoamlySpacing.space12,
                        vertical: RoamlySpacing.space4,
                      ),
                      color: isSelected
                          ? colors.primaryContainer.withValues(alpha: 0.45)
                          : colors.surface,
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            size: 20,
                            color: isSelected
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: RoamlySpacing.space8),
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: isSelected
                                        ? colors.primary
                                        : colors.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : null,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isSelected)
                  Positioned(
                    top: RoamlySpacing.space8,
                    right: RoamlySpacing.space8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.onPrimary, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow.withValues(alpha: 0.22),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.check,
                          size: 16,
                          color: colors.onPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
