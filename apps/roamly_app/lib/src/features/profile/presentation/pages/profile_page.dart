import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_auth/roamly_auth.dart';
import 'package:roamly_ui/roamly_ui.dart';

/// Displays account information and current-session controls.
final class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _confirmAndLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(AppStrings.signOutTitle),
          content: const Text(AppStrings.signOutConfirmation),
          actions: <Widget>[
            TextButton(
              key: const ValueKey<String>('cancel-logout-button'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              key: const ValueKey<String>('confirm-logout-button'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
                foregroundColor: Theme.of(dialogContext).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(AppStrings.signOut),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final email = user?.email ?? '';
    final avatarLabel = email.isEmpty
        ? '?'
        : email.substring(0, 1).toUpperCase();

    return CustomScrollView(
      key: const ValueKey<String>('profile-page'),
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            RoamlySpacing.space20,
            RoamlySpacing.space24,
            RoamlySpacing.space20,
            RoamlySpacing.space32,
          ),
          sliver: SliverList.list(
            children: <Widget>[
              Text(
                AppStrings.profile,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: RoamlySpacing.space24),
              _ProfileIdentityCard(email: email, avatarLabel: avatarLabel),
              const SizedBox(height: RoamlySpacing.space32),
              Text(
                AppStrings.account,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: RoamlySpacing.space12),
              RoamlyButton.destructive(
                key: const ValueKey<String>('profile-logout-button'),
                label: AppStrings.signOut,
                leadingIcon: const Icon(Icons.logout_rounded),
                expand: true,
                isLoading: authState.isLoading,
                onPressed: () => _confirmAndLogout(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({required this.email, required this.avatarLabel});

  final String email;
  final String avatarLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: RoamlyRadii.large,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(RoamlySpacing.space20),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: Text(
                avatarLabel,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(width: RoamlySpacing.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppStrings.signedInAs,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: RoamlySpacing.space4),
                  SelectableText(
                    email,
                    key: const ValueKey<String>('profile-email'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
