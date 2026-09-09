import 'package:flutter/material.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

import '../../../../branding/roamly_assets.dart';

final class PreferenceStepScaffold extends StatelessWidget {
  static const double _bottomActionClearance = 120;

  const PreferenceStepScaffold({
    super.key,
    required this.currentStep,
    required this.stepCount,
    required this.title,
    required this.description,
    required this.body,
    required this.onContinue,
    this.onBack,
    this.onSkip,
    this.continueLabel = AppStrings.continueLabel,
    this.isContinueEnabled = true,
    this.isSubmitting = false,
  }) : assert(stepCount > 0),
       assert(currentStep >= 0),
       assert(currentStep < stepCount);

  final int currentStep;
  final int stepCount;
  final Widget title;
  final String description;
  final Widget body;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final VoidCallback onContinue;
  final String continueLabel;
  final bool isContinueEnabled;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final backgroundAsset = brightness == Brightness.dark
        ? RoamlyAssets.splashBackgroundDark
        : RoamlyAssets.splashBackgroundLight;
    return RoamlyScaffold(
      useSafeArea: false,
      bodyPadding: EdgeInsets.zero,
      extendBody: true,
      safeAreaBottom: false,
      bottomNavigationBar: _BottomAction(
        label: continueLabel,
        isEnabled: isContinueEnabled,
        isSubmitting: isSubmitting,
        onPressed: onContinue,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Image.asset(
                backgroundAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                excludeFromSemantics: true,
                filterQuality: FilterQuality.medium,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.3),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: RoamlySpacing.space16,
              ),
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: ClampingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _StepNavigation(
                      currentStep: currentStep,
                      stepCount: stepCount,
                      onBack: onBack,
                      onSkip: onSkip,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: RoamlySpacing.space24),
                  ),
                  SliverToBoxAdapter(
                    child: DefaultTextStyle.merge(
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                      child: title,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: RoamlySpacing.space8),
                  ),
                  SliverToBoxAdapter(
                    child: Text(
                      description,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: RoamlySpacing.space24),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.only(
                      bottom: _bottomActionClearance,
                    ),
                    sliver: SliverToBoxAdapter(child: body),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _StepNavigation extends StatelessWidget {
  const _StepNavigation({
    required this.currentStep,
    required this.stepCount,
    required this.onBack,
    required this.onSkip,
  });

  final int currentStep;
  final int stepCount;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 38,
          height: 48,
          child: onBack == null
              ? null
              : IconButton(
                  key: const ValueKey<String>('preference-back'),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new),
                ),
        ),
        const SizedBox(width: RoamlySpacing.space8),
        Expanded(
          child: _StepProgress(currentStep: currentStep, stepCount: stepCount),
        ),
        const SizedBox(width: RoamlySpacing.space8),
        SizedBox(
          width: 64,
          child: onSkip == null
              ? null
              : RoamlyButton.ghost(
                  key: const ValueKey<String>('preference-skip'),
                  onPressed: onSkip,
                  label: AppStrings.skip,
                ),
        ),
      ],
    );
  }
}

final class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.currentStep, required this.stepCount});

  final int currentStep;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: AppStrings.preferenceProgress(currentStep + 1, stepCount),
      child: Row(
        children: List<Widget>.generate(stepCount, (index) {
          final isReached = index <= currentStep;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == stepCount - 1 ? 0 : RoamlySpacing.space8,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 4,
                decoration: BoxDecoration(
                  color: isReached
                      ? colors.primary
                      : colors.surfaceContainerHighest,
                  borderRadius: RoamlyRadii.pill,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

final class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.label,
    required this.isEnabled,
    required this.isSubmitting,
    required this.onPressed,
  });

  final String label;
  final bool isEnabled;
  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        RoamlySpacing.space20,
        RoamlySpacing.space12,
        RoamlySpacing.space20,
        RoamlySpacing.space16,
      ),
      child: RoamlyButton.primary(
        key: const ValueKey<String>('preference-continue'),
        label: label,
        expand: true,
        isLoading: isSubmitting,
        onPressed: isEnabled && !isSubmitting ? onPressed : null,
      ),
    );
  }
}
