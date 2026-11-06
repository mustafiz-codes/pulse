import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_typography.dart';

class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration = AppMotion.count,
    this.textAlign,
  });

  final double value;
  final String Function(double value) format;
  final TextStyle? style;
  final Duration duration;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: context.motion(duration),
      curve: AppMotion.emphasized,
      builder: (context, animated, _) {
        return Text(
          format(animated),
          style: style,
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

class DeltaChip extends StatelessWidget {
  const DeltaChip({
    super.key,
    required this.value,
    required this.label,
    this.positiveIsGood = true,
    this.neutralWhenZero = true,
    this.dense = false,
    this.showArrow = true,
  });

  final double? value;
  final String label;
  final bool positiveIsGood;
  final bool neutralWhenZero;
  final bool dense;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final theme = Theme.of(context);
    final number = value;
    final isZero = number == null || number.abs() < 0.0001;
    final favorable = number == null
        ? null
        : positiveIsGood
        ? number > 0
        : number < 0;
    final color = number == null || (neutralWhenZero && isZero)
        ? palette.textMuted
        : favorable!
        ? palette.positive
        : palette.negative;
    final background = number == null || (neutralWhenZero && isZero)
        ? palette.surfaceAlt
        : color.withValues(alpha: palette.isDark ? 0.14 : 0.10);
    final icon = isZero
        ? Icons.remove_rounded
        : number > 0
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 8,
        vertical: dense ? 2.5 : 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showArrow) ...[
            Icon(icon, size: dense ? 11 : 13, color: color),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.numeric(
                theme.textTheme.labelSmall!.copyWith(
                  fontSize: dense ? 10 : 11,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LiveDot extends StatefulWidget {
  const LiveDot({super.key, this.color, this.size = 7});

  final Color? color;
  final double size;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.pulse.accent;
    if (context.reduceMotion) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.35,
        end: 1,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
