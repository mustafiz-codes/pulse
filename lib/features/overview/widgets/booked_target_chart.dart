import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_motion.dart';
import '../../../core/analytics/analytics_bundle.dart';
import '../../../core/utils/currency_format.dart';

class BookedTargetChart extends StatelessWidget {
  const BookedTargetChart({super.key, required this.points, this.height = 210});

  final List<MonthlySalesPoint> points;
  final double height;

  /// Screen-reader summary; the chart itself is excluded from semantics.
  String _semanticsLabel() {
    final latest = points.last;
    final target = latest.targetMinor == null
        ? 'unavailable'
        : formatMoneyMinor(latest.targetMinor!, compact: true);
    return 'Booked sales chart, ${points.length} points, latest '
        '${formatMoneyMinor(latest.bookedMinor, compact: true)} against target $target';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final theme = Theme.of(context);
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('No monthly history', style: theme.textTheme.bodySmall),
        ),
      );
    }

    final hasTarget = points.any((point) => point.targetMinor != null);
    final maxValue = points.fold<double>(0, (current, point) {
      final booked = point.bookedMinor / 100;
      final target = (point.targetMinor ?? 0) / 100;
      return math.max(current, math.max(booked, target));
    });
    final maxY = math.max(1000.0, maxValue * 1.18);
    final interval = maxY / 3;

    final bookedSpots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].bookedMinor / 100),
    ];
    final targetSpots = [
      for (var i = 0; i < points.length; i++)
        if (points[i].targetMinor != null)
          FlSpot(i.toDouble(), points[i].targetMinor! / 100),
    ];

    return Semantics(
      container: true,
      label: _semanticsLabel(),
      child: ExcludeSemantics(
        child: Column(
          children: [
            Row(
              children: [
                _LegendDot(color: palette.accent, label: 'Booked'),
                const SizedBox(width: 14),
                if (hasTarget)
                  _LegendDot(color: palette.sky, label: 'Target', dashed: true),
                const Spacer(),
                Text(
                  '12 months to Oct 26',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                    fontSize: 9.5,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: height,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (points.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: palette.border.withValues(alpha: 0.7),
                      strokeWidth: 1,
                      dashArray: const [4, 5],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          if (value <= 0) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            space: 8,
                            child: Text(
                              '£${NumberFormat.compact(locale: 'en_GB').format(value)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: palette.textMuted,
                                fontSize: 9,
                                letterSpacing: 0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          if (index.isOdd && index != points.length - 1) {
                            return const SizedBox.shrink();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            space: 8,
                            child: Text(
                              points[index].label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: palette.textMuted,
                                fontSize: 9,
                                letterSpacing: 0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) => palette.surfaceAlt,
                      tooltipBorderRadius: BorderRadius.circular(12),
                      tooltipBorder: BorderSide(color: palette.border),
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      maxContentWidth: 190,
                      getTooltipItems: (spots) {
                        // fl_chart needs exactly one entry per touched spot.
                        // The booked line (bar 0) carries the whole card;
                        // the target line's spot contributes nothing.
                        final index = spots.first.x.round();
                        final point = points[index];
                        final small = theme.textTheme.bodySmall!;
                        return [
                          for (final spot in spots)
                            spot.barIndex != 0
                                ? null
                                : LineTooltipItem(
                                    '${point.label}\n',
                                    theme.textTheme.labelMedium!.copyWith(
                                      color: palette.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            'Booked  ${formatMoneyMinor(point.bookedMinor, compact: true)}',
                                        style: small.copyWith(
                                          color: palette.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (point.targetMinor != null)
                                        TextSpan(
                                          text:
                                              '\nTarget  ${formatMoneyMinor(point.targetMinor!, compact: true)}',
                                          style: small.copyWith(
                                            color: palette.sky,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                        ];
                      },
                    ),
                    getTouchedSpotIndicator: (barData, spotIndexes) {
                      return [
                        for (final _ in spotIndexes)
                          TouchedSpotIndicatorData(
                            FlLine(
                              color: palette.textMuted.withValues(alpha: 0.5),
                              strokeWidth: 1,
                              dashArray: const [3, 4],
                            ),
                            FlDotData(
                              getDotPainter: (spot, percent, barData, index) =>
                                  FlDotCirclePainter(
                                    radius: 4,
                                    color: palette.accent,
                                    strokeColor: palette.background,
                                    strokeWidth: 2,
                                  ),
                            ),
                          ),
                      ];
                    },
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: bookedSpots,
                      isCurved: true,
                      curveSmoothness: 0.24,
                      barWidth: 2.6,
                      color: palette.accent,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            palette.accent.withValues(alpha: 0.22),
                            palette.accent.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                    if (hasTarget)
                      LineChartBarData(
                        spots: targetSpots,
                        isCurved: false,
                        barWidth: 1.6,
                        color: palette.sky.withValues(alpha: 0.9),
                        dashArray: const [5, 5],
                        dotData: const FlDotData(show: false),
                      ),
                  ],
                ),
                duration: context.motion(const Duration(milliseconds: 650)),
                curve: Curves.easeOutCubic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: dashed
              ? Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      Expanded(child: ColoredBox(color: color)),
                      if (i < 2)
                        Expanded(
                          child: ColoredBox(
                            color: palette.surface.withValues(alpha: 0),
                          ),
                        ),
                    ],
                  ],
                )
              : null,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: palette.textSecondary,
            letterSpacing: 0.1,
            fontWeight: FontWeight.w500,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
