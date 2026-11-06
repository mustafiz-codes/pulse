import 'package:flutter/widgets.dart';

/// Caps content at a readable width and centres it, so tablets don't stretch
/// cards edge to edge. Phones are unaffected (they're narrower than the cap).
class PulseContentWidth extends StatelessWidget {
  const PulseContentWidth({
    super.key,
    required this.child,
    this.maxWidth = maxContentWidth,
  });

  static const double maxContentWidth = 720;

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
