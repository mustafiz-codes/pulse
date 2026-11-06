import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
    this.borderColor,
    this.gradient,
    this.radius = 16,
    this.shadow,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;
  final double radius;

  /// Overrides the default soft card shadow (light theme only).
  final List<BoxShadow>? shadow;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final radiusValue = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? palette.surface) : null,
        gradient: gradient,
        borderRadius: radiusValue,
        border: borderColor != null
            ? Border.all(color: borderColor!)
            : palette.isDark
            ? Border.all(color: palette.border.withValues(alpha: 0.6))
            : null,
        boxShadow: palette.isDark
            ? null
            : shadow ??
                  [
                    BoxShadow(
                      color: palette.cardShadow,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                    BoxShadow(
                      color: palette.cardShadow.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radiusValue,
        clipBehavior: clipBehavior,
        child: InkWell(
          onTap: onTap,
          borderRadius: radiusValue,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SurfaceTile extends StatelessWidget {
  const SurfaceTile({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.color,
    this.radius = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final radiusValue = BorderRadius.circular(radius);
    return Material(
      color: color ?? palette.surfaceAlt,
      borderRadius: radiusValue,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radiusValue,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
