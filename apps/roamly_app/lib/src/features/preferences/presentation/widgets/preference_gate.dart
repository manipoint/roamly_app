import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/features/preferences/presentation/controllers/saved_preferences_controller.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

final class PreferenceGate extends ConsumerWidget {
  const PreferenceGate({
    super.key,
    required this.loadingChild,
    required this.authenticatedChild,
    required this.onboardingChild,
  });
  final Widget loadingChild;
  final Widget authenticatedChild;
  final Widget onboardingChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(savedPreferencesControllerProvider);
    if (preferences.hasValue) {
      return preferences.requireValue.onboardingCompleted
          ? authenticatedChild
          : onboardingChild;
    }
    if (preferences.hasError) {
      return _PreferenceLoadFailure(
        onRetry: () {
          ref.read(savedPreferencesControllerProvider.notifier).reload();
        },
      );
    }
    return loadingChild;
  }
}

class _PreferenceLoadFailure extends StatelessWidget {
  const _PreferenceLoadFailure({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return RoamlyScaffold(
      maxContentWidth: 420,
      body: Center(
        child: Column(
          key: const ValueKey<String>('preference-load-failure'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: RoamlySpacing.space16),
            Text(
              AppStrings.preferencesLoadFailed,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: RoamlySpacing.space24),
            RoamlyButton.primary(
              label: AppStrings.tryAgain,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
