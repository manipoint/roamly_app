import 'package:flutter/material.dart';
import 'package:roamly_app/src/branding/widgets/roamly_app_icon.dart';
import 'package:roamly_app/src/localization/app_strings.dart';
import 'package:roamly_ui/roamly_ui.dart';

final class AssistantThinkingIndicator extends StatefulWidget {
  const AssistantThinkingIndicator({super.key});

  @override
  State<AssistantThinkingIndicator> createState() =>
      _AssistantThinkingIndicatorState();
}

class _AssistantThinkingIndicatorState extends State<AssistantThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool? _animationsDisabled;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animationsDisabled = MediaQuery.disableAnimationsOf(context);
    if (_animationsDisabled == animationsDisabled) {
      return;
    }
    _animationsDisabled = animationsDisabled;
    if (animationsDisabled) {
      _controller
        ..stop()
        ..value = .5;
      return;
    }
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _dotProgress(int index) {
    final phase = (_controller.value - (index * 0.16)) % 1.0;

    return (1 - ((phase - 0.35).abs() / 0.35)).clamp(0.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      liveRegion: true,
      label: AppStrings.assistantThinking,
      child: ExcludeSemantics(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const RoamlyAppIcon(size: 32),
              const SizedBox(width: RoamlySpacing.space8),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      final progress = _dotProgress(index);
                      return Padding(
                        padding: EdgeInsets.only(
                          right: index == 2 ? 0 : RoamlySpacing.space4,
                        ),
                        child: Opacity(
                          opacity: .3 + (progress * .7),
                          child: Transform.scale(
                            scale: 0.8 + (progress * 0.2),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const SizedBox.square(dimension: 7),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
