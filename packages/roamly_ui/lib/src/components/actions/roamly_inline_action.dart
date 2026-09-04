import 'package:flutter/material.dart';

import '../buttons/roamly_button.dart';

/// Displays supporting copy followed by a compact inline action.
///
/// A wrapping layout keeps the content usable on narrow screens and with
/// large accessibility text. Pass a null [onPressed] callback to disable the
/// action.
final class RoamlyInlineAction extends StatelessWidget {
  const RoamlyInlineAction({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onPressed,
    this.actionKey,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback? onPressed;

  /// Optional stable key applied to the interactive button.
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          prompt,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        RoamlyButton.ghost(
          key: actionKey,
          label: actionLabel,
          onPressed: onPressed,
        ),
      ],
    );
  }
}
