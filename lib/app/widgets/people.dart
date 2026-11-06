import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/utils/currency_format.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_typography.dart';

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.highlight = false,
    this.color,
  });

  final String name;
  final double size;
  final bool highlight;

  /// Fixed colour; otherwise one is derived from the name.
  final Color? color;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final colors = palette.chart;
    final hash = name.codeUnits.fold<int>(0, (sum, code) => sum + code);
    final color =
        this.color ??
        (highlight ? palette.accent : colors[hash % colors.length]);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: palette.isDark ? 0.30 : 0.20),
            color.withValues(alpha: palette.isDark ? 0.14 : 0.10),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        _initials,
        style: AppTypography.numeric(
          Theme.of(context).textTheme.labelMedium!.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.33,
          ),
        ),
      ),
    );
  }
}

class PulsePill extends StatelessWidget {
  const PulsePill({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.filled = false,
    this.dense = false,
  });

  final String label;
  final Color? color;
  final IconData? icon;
  final bool filled;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final tone = color ?? palette.textSecondary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: filled
            ? tone.withValues(alpha: palette.isDark ? 0.18 : 0.12)
            : palette.surfaceAlt,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: filled ? tone.withValues(alpha: 0.35) : palette.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 10 : 12, color: tone),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.numeric(
              Theme.of(context).textTheme.labelSmall!.copyWith(
                color: tone,
                letterSpacing: 0.1,
                fontSize: dense ? 9.5 : 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.size,
    this.strokeWidth = 8,
    this.color,
    this.trackColor,
    this.center,
    this.semanticLabel,
  });

  final double? value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final Widget? center;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final tone = color ?? palette.accent;
    return Semantics(
      label:
          semanticLabel ??
          (value == null
              ? 'Target unavailable'
              : '${formatPercent(value!)} of target'),
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value ?? 0),
          duration: context.motion(const Duration(milliseconds: 900)),
          curve: Curves.easeOutCubic,
          builder: (context, animated, _) {
            return CustomPaint(
              painter: _RingPainter(
                value: animated,
                color: tone,
                trackColor: trackColor ?? palette.surfaceAlt,
                strokeWidth: strokeWidth,
                unavailable: value == null,
              ),
              child: Center(child: center),
            );
          },
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
    required this.unavailable,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final bool unavailable;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    if (unavailable) return;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0.0, 1.0),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.color != color ||
      oldDelegate.unavailable != unavailable;
}

class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    this.color,
    this.height = 36,
    this.showFill = true,
  });

  final List<double> values;
  final Color? color;
  final double height;
  final bool showFill;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final tone = color ?? palette.accent;
    if (values.length < 2) return SizedBox(height: height);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: context.motion(const Duration(milliseconds: 800)),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) {
          return CustomPaint(
            painter: _SparklinePainter(
              values: values,
              color: tone,
              progress: progress,
              showFill: showFill,
            ),
          );
        },
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.values,
    required this.color,
    required this.progress,
    required this.showFill,
  });

  final List<double> values;
  final Color color;
  final double progress;
  final bool showFill;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxValue = values.reduce(math.max);
    final minValue = values.reduce(math.min);
    final span = math.max(0.0001, maxValue - minValue);
    final step = size.width / (values.length - 1);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = step * i;
      final y =
          size.height - ((values[i] - minValue) / span) * (size.height - 6) - 3;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * progress);
    if (showFill) {
      final fill = Path.from(drawn)
        ..lineTo(step * (values.length - 1) * progress, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Offset.zero & size),
      );
    }
    canvas.drawPath(
      drawn,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
