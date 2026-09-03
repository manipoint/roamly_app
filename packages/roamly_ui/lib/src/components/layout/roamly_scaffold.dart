import 'package:flutter/material.dart';

import '../../foundations/spacing/roamly_spacing.dart';

/// Provides the shared visual structure used by standard Roamly screens.
///
/// Feature screens compose their own content while this component applies
/// common background, spacing, safe-area, and responsive-width policies.
final class RoamlyScaffold extends StatelessWidget {
  const RoamlyScaffold({
    super.key,
    required this.body,
    this.scaffoldKey,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.bodyPadding = const EdgeInsets.symmetric(
      horizontal: RoamlySpacing.space20,
    ),
    this.maxContentWidth,
    this.useSafeArea = true,
    this.safeAreaTop,
    this.safeAreaBottom,
    this.safeAreaLeft = true,
    this.safeAreaRight = true,
    this.safeAreaMinimum = EdgeInsets.zero,
    this.maintainBottomViewPadding = false,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  }) : assert(
         maxContentWidth == null || maxContentWidth > 0,
         'maxContentWidth must be greater than zero',
       );

  /// Screen-specific content.
  final Widget body;

  /// Optional key for controlling the underlying Material scaffold.
  final GlobalKey<ScaffoldState>? scaffoldKey;

  /// Optional themed application bar.
  final PreferredSizeWidget? appBar;

  /// Optional bottom navigation or bottom action area.
  final Widget? bottomNavigationBar;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// Placement of the floating action button.
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Optional background override.
  ///
  /// The active theme surface color is used when this is null.
  final Color? backgroundColor;

  /// Padding around the screen content.
  ///
  /// Standard Roamly screens use 20 logical pixels horizontally. Full-bleed
  /// screens can pass [EdgeInsets.zero].
  final EdgeInsetsGeometry bodyPadding;

  /// Optional maximum content width for forms and tablet layouts.
  ///
  /// For example, authentication forms can use 480 while lists can leave this
  /// null and manage their own responsive grid.
  final double? maxContentWidth;

  /// Whether body content should respect system insets.
  final bool useSafeArea;

  /// Top inset policy.
  ///
  /// When null, the top inset is used only when [appBar] is absent.
  final bool? safeAreaTop;

  /// Bottom inset policy.
  ///
  /// When null, the bottom inset is used only when
  /// [bottomNavigationBar] is absent.
  final bool? safeAreaBottom;

  final bool safeAreaLeft;
  final bool safeAreaRight;
  final EdgeInsets safeAreaMinimum;
  final bool maintainBottomViewPadding;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    final shouldProtectTop = safeAreaTop ?? appBar == null;
    final shouldProtectBottom = safeAreaBottom ?? bottomNavigationBar == null;

    Widget content = body;

    if (maxContentWidth case final width?) {
      content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: content,
        ),
      );
    }

    content = Padding(padding: bodyPadding, child: content);

    if (useSafeArea) {
      content = SafeArea(
        top: shouldProtectTop,
        bottom: shouldProtectBottom,
        left: safeAreaLeft,
        right: safeAreaRight,
        minimum: safeAreaMinimum,
        maintainBottomViewPadding: maintainBottomViewPadding,
        child: content,
      );
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
      appBar: appBar,
      body: content,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}
