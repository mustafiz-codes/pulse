import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../splash/intro_controller.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class PulseMark extends StatelessWidget {
  const PulseMark({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.brandTile,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: CustomPaint(
        painter: _PulseMarkPainter(color: palette.brand, accent: palette.brand),
      ),
    );
  }
}

class _PulseMarkPainter extends CustomPainter {
  const _PulseMarkPainter({required this.color, required this.accent});

  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.17, h * 0.52)
      ..lineTo(w * 0.32, h * 0.52)
      ..lineTo(w * 0.40, h * 0.31)
      ..lineTo(w * 0.51, h * 0.74)
      ..lineTo(w * 0.61, h * 0.43)
      ..lineTo(w * 0.68, h * 0.52)
      ..lineTo(w * 0.83, h * 0.52);
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset(w * 0.51, h * 0.74),
      size.width * 0.055,
      Paint()..color = accent,
    );
  }

  @override
  bool shouldRepaint(covariant _PulseMarkPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accent != accent;
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.compact = false, this.headerLogo = false});

  final bool compact;

  /// True only for the shell header: keys the logo tile so the intro can fly
  /// onto it, and hides the tile while the intro is still playing.
  final bool headerLogo;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (headerLogo)
          Consumer(
            builder: (context, ref, child) => Opacity(
              opacity: ref.watch(introPhaseProvider) == IntroPhase.playing
                  ? 0
                  : 1,
              child: child,
            ),
            child: KeyedSubtree(
              key: pulseHeaderLogoKey,
              child: PulseMark(size: compact ? 28 : 32),
            ),
          )
        else
          PulseMark(size: compact ? 28 : 32),
        const SizedBox(width: 10),
        Text(
          'PULSE',
          style:
              (compact
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.titleLarge)
                  ?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                    color: palette.textPrimary,
                  ),
        ),
      ],
    );
  }
}

class DemoDataBadge extends StatelessWidget {
  const DemoDataBadge({super.key, this.dense = false});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: palette.brandSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'DEMO DATA',
        style: AppTypography.numeric(
          Theme.of(context).textTheme.labelSmall!.copyWith(
            fontSize: dense ? 8.5 : 9.5,
            letterSpacing: dense ? 0.9 : 1.2,
            color: palette.brandInk,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class AsOfText extends StatelessWidget {
  const AsOfText({super.key, required this.label, this.timezone});

  final String label;
  final String? timezone;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 12, color: palette.textMuted),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            timezone == null ? label : '$label · $timezone',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 0.2,
              fontWeight: FontWeight.w500,
              color: palette.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
