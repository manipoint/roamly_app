import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../../../localization/app_strings.dart';
import '../../domain/entities/canonical_location.dart';
import '../controllers/location_search_controller.dart';
import '../controllers/preference_draft_controller.dart';
import '../controllers/preference_flow_controller.dart';
import '../controllers/saved_preferences_controller.dart';
import '../state/location_search_state.dart';
import 'location_option_tile.dart';
import 'location_search_field.dart';
import 'preference_section_title.dart';
import 'preference_step_scaffold.dart';
import 'recommendation_scope_selector.dart';

final class DiscoveryScopeStep extends ConsumerStatefulWidget {
  const DiscoveryScopeStep({super.key});

  @override
  ConsumerState<DiscoveryScopeStep> createState() {
    return _DiscoveryScopeStepState();
  }
}

final class _DiscoveryScopeStepState extends ConsumerState<DiscoveryScopeStep> {
  late final TextEditingController _locationController;
  late final FocusNode _locationFocusNode;

  @override
  void initState() {
    super.initState();

    final selectedLocation = ref
        .read(preferenceDraftControllerProvider)
        .homeLocation;

    _locationController = TextEditingController(
      text: selectedLocation?.canonicalName ?? '',
    );
    _locationFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flowStep = ref.watch(preferenceFlowControllerProvider);
    final draft = ref.watch(preferenceDraftControllerProvider);
    final searchState = ref.watch(locationSearchControllerProvider);
    final savedPreferences = ref.watch(savedPreferencesControllerProvider);

    final draftController = ref.read(
      preferenceDraftControllerProvider.notifier,
    );
    final searchController = ref.read(
      locationSearchControllerProvider.notifier,
    );

    return PreferenceStepScaffold(
      currentStep: flowStep.index,
      stepCount: PreferenceFlowStep.values.length,
      continueLabel: AppStrings.finishSetup,
      isContinueEnabled: draft.canSubmit && !savedPreferences.isLoading,
      isSubmitting: savedPreferences.isLoading,
      onBack: () {
        searchController.clear();
        _locationFocusNode.unfocus();
        ref.read(preferenceFlowControllerProvider.notifier).previous();
      },
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
        unawaited(
          ref
              .read(savedPreferencesControllerProvider.notifier)
              .saveDraft(draft),
        );
      },
      title: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: AppStrings.discoveryTitlePrefix),
            TextSpan(
              text: AppStrings.discoveryTitleEmphasis,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
      description: AppStrings.discoveryDescription,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PreferenceSectionTitle(
                title: AppStrings.recommendationScopeQuestion,
              ),
              const SizedBox(height: RoamlySpacing.space12),
              RecommendationScopeSelector(
                selected: draft.recommendationScope,
                onSelected: (scope) {
                  draftController.selectRecommendationScope(scope);

                  if (!scope.requiresHomeLocation) {
                    searchController.clear();
                    _locationFocusNode.unfocus();
                  }
                },
              ),
              if (draft.recommendationScope.requiresHomeLocation) ...[
                const SizedBox(height: RoamlySpacing.space24),
                LocationSearchField(
                  controller: _locationController,
                  focusNode: _locationFocusNode,
                  isLoading: searchState.isLoading,
                  enabled: !savedPreferences.isLoading,
                  onChanged: (value) {
                    final selectedLocation = ref
                        .read(preferenceDraftControllerProvider)
                        .homeLocation;

                    if (selectedLocation != null &&
                        value.trim() != selectedLocation.canonicalName) {
                      draftController.clearHomeLocation();
                    }

                    searchController.search(value);
                  },
                  onClear: () {
                    draftController.clearHomeLocation();
                    searchController.clear();
                  },
                ),
                const SizedBox(height: RoamlySpacing.space8),
                Text(
                  AppStrings.homeCityExplanation,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: RoamlySpacing.space12),
                _LocationSearchResults(
                  state: searchState,
                  selectedLocation: draft.homeLocation,
                  onSelected: (location) {
                    draftController.selectHomeLocation(location);

                    _locationController.value = TextEditingValue(
                      text: location.canonicalName,
                      selection: TextSelection.collapsed(
                        offset: location.canonicalName.length,
                      ),
                    );

                    _locationFocusNode.unfocus();
                  },
                  onRetry: searchController.retry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final class _LocationSearchResults extends StatelessWidget {
  const _LocationSearchResults({
    required this.state,
    required this.selectedLocation,
    required this.onSelected,
    required this.onRetry,
  });

  final LocationSearchState state;
  final CanonicalLocation? selectedLocation;
  final ValueChanged<CanonicalLocation> onSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      LocationSearchStatus.success => Column(
        key: const ValueKey<String>('location-search-results'),
        children: [
          for (var index = 0; index < state.options.length; index++) ...[
            if (index > 0) const SizedBox(height: RoamlySpacing.space8),
            LocationOptionTile(
              location: state.options[index],
              isSelected: selectedLocation == state.options[index],
              onTap: () => onSelected(state.options[index]),
            ),
          ],
        ],
      ),
      LocationSearchStatus.empty => Text(
        AppStrings.noLocationsFound,
        key: const ValueKey<String>('location-search-empty'),
        textAlign: TextAlign.center,
      ),
      LocationSearchStatus.failure => Column(
        key: const ValueKey<String>('location-search-failure'),
        children: [
          Text(
            AppStrings.locationSearchFailed,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: RoamlySpacing.space8),
          RoamlyButton.ghost(label: AppStrings.tryAgain, onPressed: onRetry),
        ],
      ),
      LocationSearchStatus.idle ||
      LocationSearchStatus.loading => const SizedBox.shrink(),
    };
  }
}
