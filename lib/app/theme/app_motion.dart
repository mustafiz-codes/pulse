import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 520);
  static const count = Duration(milliseconds: 720);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const spring = Cubic(0.2, 0.9, 0.2, 1.0);
  static const emphasized = Cubic(0.16, 1, 0.3, 1);
}

/// Respect the platform's reduced-motion preference for non-essential
/// movement. Data changes still render immediately; only the interpolation is
/// removed.
extension PulseMotionContext on BuildContext {
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;

  Duration motion(Duration duration) => reduceMotion ? Duration.zero : duration;
}

class PulsePageTransitionsBuilder extends PageTransitionsBuilder {
  const PulsePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (context.reduceMotion) return child;
    return const ZoomPageTransitionsBuilder().buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
