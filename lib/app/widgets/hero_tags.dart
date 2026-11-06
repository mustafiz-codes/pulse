import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Shared-element tag for a deal's value between its pipeline card and the
/// deal detail header. Only one widget per screen may carry a given tag.
String dealHeroTag(String dealId) => 'deal-card-$dealId';

/// Key on the in-flight shuttle, so tests can tell whether a flight happened.
const pulseHeroShuttleKey = ValueKey('pulse-hero-shuttle');

/// A [Hero] tuned for PULSE: the flight scales its content to the moving
/// rect (so differently sized text morphs instead of overflowing), sits on a
/// transparent [Material] (no fallback text styling flash), and is skipped
/// entirely when the platform asks for reduced motion.
class PulseHero extends StatelessWidget {
  const PulseHero({super.key, required this.tag, required this.child});

  final String tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return child;
    return Hero(tag: tag, flightShuttleBuilder: _shuttle, child: child);
  }

  static Widget _shuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final target = direction == HeroFlightDirection.push
        ? toHeroContext
        : fromHeroContext;
    final hero = target.widget as Hero;
    return Material(
      key: pulseHeroShuttleKey,
      type: MaterialType.transparency,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        child: DefaultTextStyle(
          style: DefaultTextStyle.of(target).style,
          child: hero.child,
        ),
      ),
    );
  }
}
