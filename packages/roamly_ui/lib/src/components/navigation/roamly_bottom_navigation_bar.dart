import 'package:flutter/material.dart';

import '../../foundations/radius/roamly_radii.dart';
import '../../foundations/spacing/roamly_spacing.dart';
import '../../foundations/typography/roamly_typography.dart';

@immutable
final class RoamlyNavigationItem {
  const RoamlyNavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class RoamlyBottomNavigationBar extends StatelessWidget {
  const RoamlyBottomNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : assert(items.length == 5),
       assert(selectedIndex >= 0 && selectedIndex < 5);

  final List<RoamlyNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(
          top: RoamlySpacing.space12,
          // Lower the bar surface while keeping the raised button inside
          // the Stack's layout and hit-test bounds.
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.outlineVariant)),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              RoamlySpacing.space4,
              RoamlySpacing.none,
              RoamlySpacing.space4,
              RoamlySpacing.space8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavigationItem(
                      item: items[i],
                      selected: selectedIndex == i,
                      emphasized: i == 2,
                      onTap: () => onDestinationSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.item,
    required this.selected,
    required this.emphasized,
    required this.onTap,
  });

  static const double _iconSlotHeight = 56;
  static const double _iconSize = 28;
  static const double _labelFontSize = 10;
  static const double _labelLineHeight = 1.4;

  final RoamlyNavigationItem item;
  final bool selected;
  final bool emphasized;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.primary : colors.onSurfaceVariant;
    return Semantics(
      label: item.label,
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Tooltip(
        message: item.label,
        excludeFromSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: RoamlyRadii.large,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: RoamlySpacing.space4,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: _iconSlotHeight,
                    child: Center(
                      child: emphasized
                          ? _AssistantIcon(
                              icon: selected ? item.selectedIcon : item.icon,
                            )
                          : Padding(
                              padding: const EdgeInsets.only(
                                top: RoamlySpacing.space12,
                              ),
                              child: Icon(
                                selected ? item.selectedIcon : item.icon,
                                size: _iconSize,
                                color: foreground,
                              ),
                            ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: RoamlyTypography.caption.copyWith(
                        fontSize: _labelFontSize,
                        height: _labelLineHeight,
                        color: foreground,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantIcon extends StatelessWidget {
  const _AssistantIcon({required this.icon});
  static const double _diameter = 52;
  static const double _iconSize = 26;
  static const double _borderWidth = 4;
  static const double _shadowOpacity = 0.18;
  static const double _shadowBlurRadius = 10;
  static const Offset _shadowOffset = Offset(0, 3);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: _diameter,
      height: _diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.surface, width: _borderWidth),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.secondary, colors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: _shadowOpacity),
            blurRadius: _shadowBlurRadius,
            offset: _shadowOffset,
          ),
        ],
      ),
      child: Icon(icon, size: _iconSize, color: colors.onPrimary),
    );
  }
}
