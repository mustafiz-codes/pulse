import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../widgets/brand.dart';
import 'intro_controller.dart';

/// Total length of the cold-start intro.
const pulseIntroDuration = Duration(milliseconds: 1800);

/// Size of the centred logo tile before it flies to the header.
const double _introLogoSize = 70;

/// Sits above the router and shows the intro on top of the app until it ends.
class PulseIntroHost extends ConsumerWidget {
  const PulseIntroHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(introPhaseProvider) == IntroPhase.playing;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (playing) const PulseIntroOverlay(key: ValueKey('pulse-intro')),
      ],
    );
  }
}

/// Heartbeat sweep → ping → logo + wordmark → logo flies into the header
/// while the app fades up underneath. Tap anywhere to skip.
class PulseIntroOverlay extends ConsumerStatefulWidget {
  const PulseIntroOverlay({super.key});

  @override
  ConsumerState<PulseIntroOverlay> createState() => _PulseIntroOverlayState();
}

class _PulseIntroOverlayState extends ConsumerState<PulseIntroOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Rect? _target;
  bool _started = false;

  // Phase windows on the 0–1 timeline.
  static const _line = Interval(0.00, 0.28, curve: Curves.easeInOut);
  static const _ping = Interval(0.28, 0.39, curve: Curves.easeOut);
  static const _lineOut = Interval(0.33, 0.42, curve: Curves.easeOut);
  static const _brandIn = Interval(0.39, 0.56, curve: Curves.easeOut);
  static const _flight = Interval(0.72, 1.00, curve: AppMotion.emphasized);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: pulseIntroDuration)
      ..addListener(_captureTarget)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (context.reduceMotion) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else {
      _controller.forward();
    }
  }

  void _captureTarget() {
    if (_target != null || _controller.value < _flight.begin) return;
    final box =
        pulseHeaderLogoKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || overlay == null) return;
    final topLeft = overlay.globalToLocal(box.localToGlobal(Offset.zero));
    _target = topLeft & box.size;
  }

  void _finish() {
    if (!mounted) return;
    ref.read(introPhaseProvider.notifier).finish();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _t(Interval interval) => interval.transform(_controller.value);

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final theme = Theme.of(context);
    if (context.reduceMotion) return const SizedBox.shrink();
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: Semantics(
          label: 'PULSE, Sales Command Centre. Tap to skip.',
          button: true,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final size = MediaQuery.sizeOf(context);
              final centre = Rect.fromCenter(
                center: Offset(size.width / 2, size.height / 2 - 40),
                width: _introLogoSize,
                height: _introLogoSize,
              );
              final flight = _t(_flight);
              final target = _target;
              final logoRect = target == null
                  ? centre
                  : Rect.lerp(centre, target, flight)!;
              final logoOpacity = target == null
                  ? _t(_brandIn) * (1 - flight)
                  : _t(_brandIn);
              final wordOpacity = _t(_brandIn) * (1 - (flight * 2).clamp(0, 1));
              final backdrop = 1 - flight;
              final brandScale = 0.92 + 0.08 * _t(_brandIn);

              return Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: backdrop,
                    child: ColoredBox(color: palette.background),
                  ),
                  Opacity(
                    opacity: 1 - _t(_lineOut),
                    child: CustomPaint(
                      painter: _HeartbeatPainter(
                        progress: _t(_line),
                        ping: _controller.value < _ping.begin ? 0 : _t(_ping),
                        color: palette.accent,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: centre.bottom + 18,
                    child: Opacity(
                      opacity: wordOpacity,
                      child: Transform.scale(
                        scale: brandScale,
                        child: Column(
                          children: [
                            Text(
                              'PULSE',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 5,
                                color: palette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sales Command Centre',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: palette.textMuted,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: logoRect,
                    child: Opacity(
                      opacity: logoOpacity.clamp(0, 1),
                      child: Transform.scale(
                        scale: target == null || flight == 0 ? brandScale : 1,
                        child: FittedBox(
                          key: const ValueKey('pulse-intro-logo'),
                          child: const PulseMark(size: _introLogoSize),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Draws the heartbeat line left to right, plus a ripple at its peak.
class _HeartbeatPainter extends CustomPainter {
  const _HeartbeatPainter({
    required this.progress,
    required this.ping,
    required this.color,
  });

  final double progress;
  final double ping;
  final Color color;

  static const _points = <Offset>[
    Offset(0.00, 0),
    Offset(0.36, 0),
    Offset(0.41, 0),
    Offset(0.44, -27),
    Offset(0.49, 29),
    Offset(0.53, -15),
    Offset(0.56, 0),
    Offset(0.61, 0),
    Offset(1.00, 0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final midY = size.height / 2 - 40;
    final path = Path();
    for (var i = 0; i < _points.length; i++) {
      final p = Offset(_points[i].dx * size.width, midY + _points[i].dy);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final PathMetric metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
    if (ping > 0 && ping < 1) {
      final peak = Offset(0.44 * size.width, midY - 27);
      canvas.drawCircle(
        peak,
        7 * (1 + 4 * ping),
        Paint()..color = color.withValues(alpha: 0.9 * (1 - ping)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeartbeatPainter old) =>
      old.progress != progress || old.ping != ping || old.color != color;
}
