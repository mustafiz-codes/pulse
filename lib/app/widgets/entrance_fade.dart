import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Fades and lifts its child in when first built. Give it a key that changes
/// with the active filter and list items re-enter on every filter change
/// while lazy lists stay lazy. Reduced motion renders the child at rest.
class EntranceFade extends StatelessWidget {
  const EntranceFade({
    super.key,
    required this.child,
    this.duration = AppMotion.standard,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: context.motion(duration),
      curve: AppMotion.enter,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 8),
          child: child,
        ),
      ),
    );
  }
}
