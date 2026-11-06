import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// Plain page background. [heroWash] adds Overview's soft colour wash behind
/// the top of the screen.
class PulseBackground extends StatelessWidget {
  const PulseBackground({
    super.key,
    required this.child,
    this.heroWash = false,
    this.padding,
  });

  final Widget child;
  final bool heroWash;
  final EdgeInsetsGeometry? padding;

  static const double washHeight = 320;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    return ColoredBox(
      color: palette.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: washHeight,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: heroWash ? 1 : 0,
                duration: context.motion(AppMotion.standard),
                curve: AppMotion.enter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        palette.heroWash,
                        Color.lerp(palette.heroWash, palette.background, 0.55)!,
                        palette.background,
                      ],
                      stops: const [0, 0.6, 1],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ],
      ),
    );
  }
}
