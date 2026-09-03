import 'package:flutter/material.dart';

enum RoamlyButtonVariant { primary, secondary, ghost }

final class RoamlyButton extends StatelessWidget {
  const RoamlyButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.isLoading = false,
    this.expand = false,
  }) : variant = RoamlyButtonVariant.primary;

  const RoamlyButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.isLoading = false,
    this.expand = false,
  }) : variant = RoamlyButtonVariant.secondary;

  const RoamlyButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.isLoading = false,
    this.expand = false,
  }) : variant = RoamlyButtonVariant.ghost;

  final String label;
  final VoidCallback? onPressed;
  final Widget? leadingIcon;
  final bool isLoading;
  final bool expand;
  final RoamlyButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
                semanticsLabel: label,
              ),
            )
          : _ButtonContent(
              key: const ValueKey('content'),
              label: label,
              leadingIcon: leadingIcon,
            ),
    );

    final button = switch (variant) {
      RoamlyButtonVariant.primary => FilledButton(
        onPressed: effectiveOnPressed,
        child: content,
      ),
      RoamlyButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        child: content,
      ),
      RoamlyButtonVariant.ghost => TextButton(
        onPressed: effectiveOnPressed,
        child: content,
      ),
    };

    if (!expand) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}

final class _ButtonContent extends StatelessWidget {
  const _ButtonContent({super.key, required this.label, this.leadingIcon});

  final String label;
  final Widget? leadingIcon;

  @override
  Widget build(BuildContext context) {
    if (leadingIcon == null) {
      return Text(label, textAlign: TextAlign.center);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconTheme.merge(
          data: const IconThemeData(size: 20),
          child: leadingIcon!,
        ),
        const SizedBox(width: 8),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
  }
}
