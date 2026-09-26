import 'package:flutter/widgets.dart';

import '../../foundations/spacing/roamly_spacing.dart';

/// Reusable widget gaps; [RoamlySpacing] remains the numeric token API.
final class RoamlyGap extends StatelessWidget {
  /// A gap tied to a custom layout dimension.
  const RoamlyGap.vertical(double size, {super.key})
    : height = size,
      width = null;

  /// A gap tied to a custom layout dimension.
  const RoamlyGap.horizontal(double size, {super.key})
    : width = size,
      height = null;

  final double? width;
  final double? height;

  static const h4 = SizedBox(height: RoamlySpacing.space4);
  static const h8 = SizedBox(height: RoamlySpacing.space8);
  static const h12 = SizedBox(height: RoamlySpacing.space12);
  static const h16 = SizedBox(height: RoamlySpacing.space16);
  static const h20 = SizedBox(height: RoamlySpacing.space20);
  static const h24 = SizedBox(height: RoamlySpacing.space24);
  static const h32 = SizedBox(height: RoamlySpacing.space32);
  static const h40 = SizedBox(height: RoamlySpacing.space40);
  static const h48 = SizedBox(height: RoamlySpacing.space48);
  static const h64 = SizedBox(height: RoamlySpacing.space64);

  static const w4 = SizedBox(width: RoamlySpacing.space4);
  static const w8 = SizedBox(width: RoamlySpacing.space8);
  static const w12 = SizedBox(width: RoamlySpacing.space12);
  static const w16 = SizedBox(width: RoamlySpacing.space16);
  static const w20 = SizedBox(width: RoamlySpacing.space20);
  static const w24 = SizedBox(width: RoamlySpacing.space24);
  static const w32 = SizedBox(width: RoamlySpacing.space32);
  static const w40 = SizedBox(width: RoamlySpacing.space40);
  static const w48 = SizedBox(width: RoamlySpacing.space48);
  static const w64 = SizedBox(width: RoamlySpacing.space64);

  @override
  Widget build(BuildContext context) => SizedBox(width: width, height: height);
}
