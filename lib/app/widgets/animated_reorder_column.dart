import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// A fixed-extent column whose rows glide to their new slot when [ids] are
/// reordered. Each row is keyed by its id, so state and identity follow the
/// item rather than the index. Reduced motion snaps rows into place.
class AnimatedReorderColumn extends StatelessWidget {
  const AnimatedReorderColumn({
    super.key,
    required this.ids,
    required this.itemBuilder,
    required this.itemExtent,
    this.duration = AppMotion.standard,
  });

  final List<Object> ids;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double itemExtent;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion(duration);
    return SizedBox(
      height: ids.length * itemExtent,
      child: Stack(
        children: [
          for (var i = 0; i < ids.length; i++)
            AnimatedPositioned(
              key: ValueKey(ids[i]),
              duration: motion,
              curve: AppMotion.emphasized,
              top: i * itemExtent,
              left: 0,
              right: 0,
              height: itemExtent,
              child: itemBuilder(context, i),
            ),
        ],
      ),
    );
  }
}
