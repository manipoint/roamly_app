import 'package:flutter/material.dart';

enum RoamlyButtonVariant { primary, secondary, ghost, destructive }

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

  const RoamlyButton.destructive({
    super.key,
    required this.label,
    this.onPressed,
    this.leadingIcon,
    this.isLoading = false,
    this.expand = false,
  }) : variant = RoamlyButtonVariant.destructive;

  final String label;
  final VoidCallback? onPressed;
  final Widget? leadingIcon;
  final bool isLoading;
  final bool expand;
  final RoamlyButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final effectiveOnPressed = isLoading ? null : onPressed;
    final loadingStyle = isLoading
        ? switch (variant) {
            RoamlyButtonVariant.primary => ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(colors.primary),
              foregroundColor: WidgetStatePropertyAll(colors.onPrimary),
            ),
            RoamlyButtonVariant.secondary => ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(colors.primary),
              side: WidgetStatePropertyAll(
                BorderSide(color: colors.primary, width: 1.5),
              ),
            ),
            RoamlyButtonVariant.ghost => ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(colors.primary),
            ),
            RoamlyButtonVariant.destructive => ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(colors.error),
              side: WidgetStatePropertyAll(
                BorderSide(color: colors.error, width: 1.5),
              ),
            ),
          }
        : null;
    final loadingIndicatorColor = switch (variant) {
      RoamlyButtonVariant.primary => colors.onPrimary,
      RoamlyButtonVariant.secondary ||
      RoamlyButtonVariant.ghost => colors.primary,
      RoamlyButtonVariant.destructive => colors.error,
    };
    final content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: loadingIndicatorColor,
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
        style: loadingStyle,
        child: content,
      ),
      RoamlyButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        style: loadingStyle,
        child: content,
      ),
      RoamlyButtonVariant.ghost => TextButton(
        onPressed: effectiveOnPressed,
        style: loadingStyle,
        child: content,
      ),
      RoamlyButtonVariant.destructive => OutlinedButton(
        onPressed: effectiveOnPressed,
        style:
            loadingStyle ??
            OutlinedButton.styleFrom(
              foregroundColor: colors.error,
              side: BorderSide(color: colors.error, width: 1.5),
            ),
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
