import 'package:flutter/material.dart';

import '../../foundations/radius/roamly_radii.dart';


final class RoamlySelectableCard extends StatelessWidget {
  const RoamlySelectableCard({
    super.key,
    required this.isSelected,
    required this.onTap,
    required this.semanticLabel,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.constraints,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final String semanticLabel;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticLabel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: constraints,
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryContainer : colors.surface,
          borderRadius: RoamlyRadii.medium,
          border: Border.all(
            color: isSelected ? colors.primary : colors.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
