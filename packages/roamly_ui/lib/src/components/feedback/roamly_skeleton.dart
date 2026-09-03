import 'package:flutter/material.dart';

/// A theme-aware loading placeholder with an optional shimmer animation.
///
/// Prefer composing this primitive into feature-specific placeholders such as
/// trip cards, hotel cards, and itinerary rows.
class RoamlySkeleton extends StatefulWidget {
  RoamlySkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.animate = true,
  }) : assert(width >= 0 && !width.isNaN, 'width must be non-negative'),
       assert(height >= 0 && !height.isNaN, 'height must be non-negative'),
       assert(
         shape != BoxShape.circle || borderRadius == null,
         'A circular skeleton cannot have a border radius',
       );

  /// Horizontal size of the placeholder.
  final double width;

  /// Vertical size of the placeholder.
  final double height;

  /// Corner radius used by rectangular placeholders.
  final BorderRadiusGeometry? borderRadius;

  /// Whether the placeholder is rectangular or circular.
  final BoxShape shape;

  /// Whether the shimmer animation should run.
  ///
  /// Animation is automatically disabled when the operating system requests
  /// reduced motion.
  final bool animate;

  @override
  State<RoamlySkeleton> createState() => _RoamlySkeletonState();
}

class _RoamlySkeletonState extends State<RoamlySkeleton>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 1200);
  late final AnimationController _animationController;
  bool _shouldAnimate = false;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _synchronizeAnimation();
  }

  @override
  void didUpdateWidget(covariant RoamlySkeleton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      _synchronizeAnimation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = Color.alphaBlend(
      colorScheme.onSurface.withValues(alpha: .08),
      colorScheme.surface,
    );
    final highlightColor = Color.alphaBlend(
      colorScheme.onSurface.withAlpha(16),
      colorScheme.surface,
    );

    return ExcludeSemantics(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: ((context, child) {
            return DecoratedBox(
              decoration: _buildDecoration(
                baseColor: baseColor,
                highlightColor: highlightColor,
              ),
            );
          }),
        ),
      ),
    );
  }

  void _synchronizeAnimation() {
    final animationsDisabled = MediaQuery.disableAnimationsOf(context);
    final shouldAnimate = widget.animate && !animationsDisabled;
    if (_shouldAnimate == shouldAnimate) {
      return;
    }
    _shouldAnimate = shouldAnimate;
    if (_shouldAnimate) {
      _animationController.repeat();
      return;
    }
    _animationController
      ..stop()
      ..value = 0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Decoration _buildDecoration({
    required Color baseColor,
    required Color highlightColor,
  }) {
    if (!_shouldAnimate) {
      return BoxDecoration(
        color: baseColor,
        shape: widget.shape,
        borderRadius: _effectiveBorderRadius,
      );
    }
    final position = (_animationController.value * 6) - 3;
    return BoxDecoration(
      shape: widget.shape,
      borderRadius: _effectiveBorderRadius,
      gradient: LinearGradient(
        begin: Alignment(position - 1, 0),
        end: Alignment(position + 1, 0),

        colors: [baseColor, highlightColor, baseColor],
        stops: const [0, .5, 1],
      ),
    );
  }

  BorderRadiusGeometry? get _effectiveBorderRadius {
    if (widget.shape == BoxShape.circle) {
      return null;
    }
    return widget.borderRadius;
  }
}
