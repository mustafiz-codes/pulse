import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 158,
    this.spacing = 12,
    this.maxColumns = 4,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        var columns = ((width + spacing) / (minItemWidth + spacing)).floor();
        columns = columns.clamp(1, maxColumns);
        if (width < minItemWidth) columns = 1;
        final itemWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class ShareSegment {
  const ShareSegment({
    required this.label,
    required this.value,
    required this.color,
    this.detail,
  });

  final String label;
  final double value;
  final Color color;

  /// Optional value shown before the share in legends (e.g. "£36.9k").
  final String? detail;
}

class StackedShareBar extends StatelessWidget {
  const StackedShareBar({
    super.key,
    required this.segments,
    this.height = 12,
    this.radius = 99,
    this.gap = 3,
    this.selectedIndex,
    this.onSegmentTap,
    this.semanticsSuffix = '',
  });

  final List<ShareSegment> segments;
  final double height;
  final double radius;
  final double gap;

  /// When set, other segments dim so the selection reads at a glance.
  final int? selectedIndex;
  final ValueChanged<int>? onSegmentTap;

  /// Appended to the spoken share list, e.g. ' of logged time'.
  final String semanticsSuffix;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final total = segments.fold<double>(
      0,
      (sum, segment) => sum + segment.value,
    );
    final spoken = total <= 0
        ? 'No logged time'
        : '${segments.map((s) => '${s.label} ${(s.value / total * 100).round()}%').join(', ')}$semanticsSuffix';
    return Semantics(
      container: true,
      label: spoken,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: context.motion(const Duration(milliseconds: 800)),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: SizedBox(
              height: height,
              child: total <= 0
                  ? ColoredBox(color: palette.surfaceAlt)
                  : Row(
                      // Segments fill the bar's height (a ColoredBox has none
                      // of its own).
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < segments.length; i++) ...[
                          if (i > 0) SizedBox(width: gap),
                          Expanded(
                            flex: math.max(
                              1,
                              (segments[i].value / total * 1000).round(),
                            ),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: onSegmentTap == null
                                  ? null
                                  : () => onSegmentTap!(i),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress,
                                child: ColoredBox(
                                  color:
                                      selectedIndex == null ||
                                          selectedIndex == i
                                      ? segments[i].color
                                      : segments[i].color.withValues(
                                          alpha: 0.35,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class ShareLegend extends StatelessWidget {
  const ShareLegend({
    super.key,
    required this.segments,
    this.showValues = true,
    this.total,
    this.selectedIndex,
    this.onTap,
  });

  final List<ShareSegment> segments;
  final bool showValues;
  final double? total;

  /// Tappable legend rows are the accessible, non-gesture alternative to
  /// tapping a thin chart segment.
  final int? selectedIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final theme = Theme.of(context);
    final denominator =
        total ?? segments.fold<double>(0, (sum, item) => sum + item.value);
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        for (final (index, segment) in segments.indexed)
          _legendItem(
            context,
            index,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: segment.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  segment.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                if (showValues) ...[
                  const SizedBox(width: 5),
                  Text(
                    denominator == 0
                        ? (segment.detail ?? '—')
                        : [
                            ?segment.detail,
                            '${(segment.value / denominator * 100).round()}%',
                          ].join(' · '),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _legendItem(BuildContext context, int index, Widget row) {
    final tap = onTap;
    if (tap == null) return row;
    final palette = context.pulse;
    final selected = selectedIndex == index;
    return Material(
      color: selected ? palette.surfaceAlt : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => tap(index),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                row,
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: palette.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HBar extends StatelessWidget {
  const HBar({
    super.key,
    required this.value,
    this.color,
    this.height = 6,
    this.background,
  });

  final double value;
  final Color? color;
  final double height;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: background ?? palette.surfaceAlt),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: context.motion(const Duration(milliseconds: 700)),
              curve: Curves.easeOutCubic,
              builder: (context, animated, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: animated,
                  child: ColoredBox(color: color ?? palette.accent),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
