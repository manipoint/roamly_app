import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

class AssistantMessageContent extends StatelessWidget {
  const AssistantMessageContent({
    super.key,
    required this.content,
    required this.foregroundColor,
    this.renderMarkdown = false,
  });
  final String content;
  final Color foregroundColor;
  final bool renderMarkdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(
      color: foregroundColor,
    );
    final codeStyle = theme.textTheme.bodyMedium?.copyWith(
      color: foregroundColor,
      fontFamily: 'monospace',
    );
    if (!renderMarkdown) {
      return SelectableText(content, style: bodyStyle);
    }
    return MarkdownBody(
      data: content,
      selectable: true,
      softLineBreak: true,
      imageBuilder: (uri, title, alt) => Tooltip(
        message: AppStrings.assistantExternalImageBlocked,
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 20,
          color: foregroundColor,
        ),
      ),
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: bodyStyle,
        pPadding: EdgeInsets.zero,
        a: bodyStyle?.copyWith(
          color: colors.primary,
          decoration: TextDecoration.underline,
          decorationColor: colors.primary,
        ),
        strong: bodyStyle?.copyWith(fontWeight: FontWeight.w700),
        em: bodyStyle?.copyWith(fontStyle: FontStyle.italic),
        del: bodyStyle?.copyWith(decoration: TextDecoration.lineThrough),
        h1: theme.textTheme.titleLarge?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
        h2: theme.textTheme.titleMedium?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
        h3: theme.textTheme.titleSmall?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
        h4: bodyStyle?.copyWith(fontWeight: FontWeight.w700),
        h5: bodyStyle?.copyWith(fontWeight: FontWeight.w700),
        h6: bodyStyle?.copyWith(fontWeight: FontWeight.w700),
        listBullet: bodyStyle,
        listIndent: RoamlySpacing.space24,
        blockSpacing: RoamlySpacing.space8,
        blockquote: bodyStyle,
        blockquoteDecoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: RoamlyRadii.small,
          border: BorderDirectional(
            start: BorderSide(color: colors.primary, width: 3),
          ),
        ),
        code: codeStyle,
        codeblockPadding: const EdgeInsets.all(RoamlySpacing.space12),
        codeblockDecoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: RoamlyRadii.small,
        ),
        tableHead: bodyStyle?.copyWith(fontWeight: FontWeight.w700),
        tableBody: bodyStyle,
        tableBorder: TableBorder.all(color: colors.outlineVariant),
        tableCellsPadding: const EdgeInsets.all(RoamlySpacing.space8),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
      ),
    );
  }
}
