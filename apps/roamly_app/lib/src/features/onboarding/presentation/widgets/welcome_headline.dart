import 'package:flutter/material.dart';
import 'package:roamly_app/src/localization/app_strings.dart';

/// Displays the two-tone marketing headline used by onboarding.
final class WelcomeHeadline extends StatelessWidget {
  const WelcomeHeadline({super.key});

  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.headlineLarge;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label:
          '${AppStrings.welcomeHeadlineFirstLine} '
          '${AppStrings.welcomeHeadlineSecondLine} '
          '${AppStrings.welcomeHeadlineEmphasis}',
      child: ExcludeSemantics(
        child: Column(
          key: const ValueKey<String>('welcome-headline'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _HeadlineLine(
              text: AppStrings.welcomeHeadlineFirstLine,
              style: headlineStyle,
            ),
            _HeadlineLine(
              text: AppStrings.welcomeHeadlineSecondLine,
              style: headlineStyle,
            ),
            _HeadlineLine(
              text: AppStrings.welcomeHeadlineEmphasis,
              style: headlineStyle?.copyWith(color: colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

final class _HeadlineLine extends StatelessWidget {
  const _HeadlineLine({required this.text, required this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}
