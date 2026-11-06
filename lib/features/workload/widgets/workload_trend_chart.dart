import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_motion.dart';
import '../../../core/analytics/workload_metrics.dart';
import '../../../core/utils/date_format.dart';

class WorkloadTrendChart extends StatelessWidget {
  const WorkloadTrendChart({
    super.key,
    required this.points,
    this.height = 190,
  });

  final List<WorkloadTrendPoint> points;
  final double height;

  /// Screen-reader summary; the chart itself is excluded from semantics.
  String _semanticsLabel() {
    final latest = points.last;
    return 'Logged time trend, ${points.length} periods, latest sales '
        '${formatMinutes(latest.salesMinutes)}, operations '
        '${formatMinutes(latest.operationsMinutes)}, other '
        '${formatMinutes(latest.otherMinutes)}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final theme = Theme.of(context);
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No logged time in this period.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      );
    }

    final maxMinutes = points.fold<int>(
      0,
      (current, point) => math.max(current, point.totalMinutes),
    );
    final maxHours = math.max(1.0, maxMinutes / 60 * 1.18);
    final interval = math.max(1.0, (maxHours / 3).ceilToDouble());

    return Semantics(
      container: true,
      label: _semanticsLabel(),
      child: ExcludeSemantics(
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _Legend(color: palette.accent, label: 'Sales'),
                      _Legend(color: palette.sky, label: 'Operations'),
                      _Legend(color: palette.violet, label: 'Other'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Hours logged',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                    fontSize: 9,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: height,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxHours,
                  minY: 0,
                  groupsSpace: 8,
                  barGroups: [
                    for (var i = 0; i < points.length; i++)
                      _group(i, points[i], palette),
                  ],
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
                        reservedSize: 30,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          if (value <= 0) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            space: 6,
                            child: Text(
                              '${value.round()}h',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: palette.textMuted,
                                fontSize: 8.5,
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
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          final skip = points.length > 8 && index.isOdd;
                          if (skip) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            space: 6,
                            child: Text(
                              points[index].label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: palette.textMuted,
                                fontSize: 8.5,
                                letterSpacing: 0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => palette.surfaceAlt,
                      tooltipBorder: BorderSide(color: palette.border),
                      tooltipBorderRadius: BorderRadius.circular(12),
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 8,
                      ),
                      maxContentWidth: 190,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final point = points[group.x];
                        return BarTooltipItem(
                          '${point.label}\n',
                          theme.textTheme.labelMedium!.copyWith(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  'Sales  ${formatMinutes(point.salesMinutes)}\n',
                              style: theme.textTheme.bodySmall!.copyWith(
                                color: palette.accent,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Ops  ${formatMinutes(point.operationsMinutes)}\n',
                              style: theme.textTheme.bodySmall!.copyWith(
                                color: palette.sky,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'Other  ${formatMinutes(point.otherMinutes)}',
                              style: theme.textTheme.bodySmall!.copyWith(
                                color: palette.violet,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
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

  BarChartGroupData _group(
    int index,
    WorkloadTrendPoint point,
    PulsePalette palette,
  ) {
    final sales = point.salesMinutes / 60;
    final operations = point.operationsMinutes / 60;
    final other = point.otherMinutes / 60;
    final total = sales + operations + other;
    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: total,
          width: points.length > 10 ? 10 : 16,
          borderRadius: BorderRadius.circular(5),
          rodStackItems: [
            if (sales > 0) BarChartRodStackItem(0, sales, palette.accent),
            if (operations > 0)
              BarChartRodStackItem(sales, sales + operations, palette.sky),
            if (other > 0)
              BarChartRodStackItem(sales + operations, total, palette.violet),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: palette.textSecondary,
            fontSize: 9.5,
            letterSpacing: 0.1,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
