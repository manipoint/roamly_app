import 'package:flutter/widgets.dart';

final class RoamlySkeleton extends StatelessWidget {
  const RoamlySkeleton({super.key, required this.width, required this.height, this.borderRadius, this.shape = BoxShape.rectangle, this.animate = true});
  final double width;
  final double height;
  final double? borderRadius;
  final BoxShape? shape;
  final bool? animate;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
