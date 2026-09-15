import 'package:flutter/material.dart';
import 'package:roamly_app/src/features/home/presentation/constants/home_layout.dart';
import 'package:roamly_ui/roamly_ui.dart';

final class DestinationDetailLoadingView extends StatelessWidget {
  const DestinationDetailLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: HomeLayout.heroImageAspectRatio,
            child: RoamlySkeleton(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.zero,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              RoamlySpacing.space20,
              RoamlySpacing.space24,
              RoamlySpacing.space20,
              RoamlySpacing.space40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RoamlySkeleton(width: 200, height: 30),
                const SizedBox(height: RoamlySpacing.space8),
                RoamlySkeleton(width: 120, height: 18),
                const SizedBox(height: RoamlySpacing.space24),
                RoamlySkeleton(width: double.infinity, height: 22),
                const SizedBox(height: RoamlySpacing.space12),
                RoamlySkeleton(width: double.infinity, height: 16),
                const SizedBox(height: RoamlySpacing.space8),
                RoamlySkeleton(width: double.infinity, height: 16),
                const SizedBox(height: RoamlySpacing.space8),
                RoamlySkeleton(width: 240, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
