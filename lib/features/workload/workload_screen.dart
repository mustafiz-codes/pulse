import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/feedback/haptics.dart';
import '../../app/shell/pulse_shell.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/semantic_colors.dart';
import '../../app/widgets/app_card.dart';
import '../../app/widgets/filter_bar.dart';
import '../../app/widgets/layout.dart';
import '../../app/widgets/metric_info.dart';
import '../../app/widgets/numbers.dart';
import '../../app/widgets/people.dart';
import '../../app/widgets/section.dart';
import '../../core/analytics/analytics_bundle.dart';
import '../../core/analytics/workload_metrics.dart';
import '../../core/data/providers.dart';
import '../../core/models/enums.dart';
import '../../core/utils/currency_format.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/labels.dart';
import 'widgets/category_activities_sheet.dart';
import 'widgets/workload_trend_chart.dart';

class WorkloadScreen extends ConsumerWidget {
  const WorkloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(analyticsBundleProvider);
    final workload = bundle.workload;
    final theme = Theme.of(context);
    final palette = context.pulse;
    final segments = _segments(workload, palette);
    final subcategories = workload.subcategories.take(10).toList();
    final maxSubcategoryMinutes = subcategories.isEmpty
        ? 1
        : subcategories.first.minutes;

    return PulseDetailScaffold(
      title: 'Workload',
      subtitle: bundle.window.label,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          const AnalyticsFilterBar(),
          const SizedBox(height: 16),
          if (bundle.filter.unitId != null) ...[
            InfoBanner(
              icon: Icons.filter_alt_outlined,
              title: '${unitLabel(bundle.filter.unitId!)} activities only',
              message: 'Internal time not assigned to a unit is excluded.',
            ),
            const SizedBox(height: 12),
          ],
          ResponsiveGrid(
            children: [
              KpiCard(
                label: 'Logged time',
                value: AnimatedNumber(
                  value: workload.totalMinutes.toDouble(),
                  format: (value) => formatMinutes(value.round()),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 28,
                  ),
                ),
                footnote: '${workload.validActivities} valid activities',
                icon: Icons.timer_outlined,
              ),
              KpiCard(
                label: 'Operations share',
                metricKey: 'opsShare',
                value: AnimatedNumber(
                  value: (workload.operationsShare ?? 0) * 100,
                  format: (value) => workload.operationsShare == null
                      ? '—'
                      : '${value.toStringAsFixed(0)}%',
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 28,
                    color:
                        workload.operationsShare != null &&
                            workload.operationsShare! >= 0.3
                        ? palette.amber
                        : null,
                  ),
                ),
                delta: DeltaChip(
                  value: bundle.opsShareDeltaPoints,
                  label: bundle.opsShareDeltaPoints == null
                      ? 'No prior data'
                      : formatPercentagePoints(bundle.opsShareDeltaPoints!),
                  positiveIsGood: false,
                ),
                footnote: 'of all logged time',
              ),
              KpiCard(
                label: 'Sales time',
                metricKey: 'salesTime',
                value: AnimatedNumber(
                  value: workload.salesMinutes.toDouble(),
                  format: (value) => formatMinutes(value.round()),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 28,
                  ),
                ),
                footnote: workload.salesShare == null
                    ? 'no logged time'
                    : '${formatPercent(workload.salesShare!)} of logged time',
              ),
              KpiCard(
                label: 'Logged-time coverage',
                metricKey: 'dataCompleteness',
                value: AnimatedNumber(
                  value: (workload.coverage ?? 0) * 100,
                  format: (value) => workload.coverage == null
                      ? '—'
                      : '${value.toStringAsFixed(0)}%',
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 28,
                  ),
                ),
                footnote:
                    '${workload.missingDurationActivities} activities without duration',
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (workload.insufficient)
            InfoBanner(
              title: 'Insufficient logged time',
              message:
                  'Only ${workload.validActivities} valid activities are in this window. '
                  'Treat the shares below as indicative rather than representative.',
              color: palette.amber,
              icon: Icons.info_outline_rounded,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final split = _SplitCard(bundle: bundle, segments: segments);
                final trend = _TrendCard(bundle: bundle);
                if (constraints.maxWidth < 760) {
                  return Column(
                    children: [split, const SizedBox(height: 12), trend],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: split),
                    const SizedBox(width: 12),
                    Expanded(flex: 6, child: trend),
                  ],
                );
              },
            ),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Subcategory breakdown',
            subtitle: 'Top logged work types across the selected context',
          ),
          AppCard(
            child: subcategories.isEmpty
                ? Text(
                    'No classified logged time in this period.',
                    style: theme.textTheme.bodySmall,
                  )
                : Column(
                    children: [
                      for (var i = 0; i < subcategories.length; i++) ...[
                        _SubcategoryRow(
                          item: subcategories[i],
                          maxMinutes: maxSubcategoryMinutes,
                        ),
                        if (i < subcategories.length - 1)
                          const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Workload by rep',
            subtitle: 'Sorted by operations minutes · tap for a full profile',
            action: PulsePill(
              label: '${workload.reps.length} reps',
              dense: true,
              filled: true,
              color: palette.textSecondary,
            ),
          ),
          if (workload.reps.isEmpty)
            const EmptyState(
              title: 'No reps in context',
              message: 'Clear the owner or team filter to see the full team.',
              icon: Icons.groups_outlined,
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < workload.reps.length; i++) ...[
                    _RepWorkloadRow(
                      rep: workload.reps[i],
                      topOperations:
                          workload.topOperationsRep?.user.id ==
                          workload.reps[i].user.id,
                    ),
                    if (i < workload.reps.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Divider(color: palette.border),
                      ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.fact_check_outlined,
                      size: 16,
                      color: palette.amber,
                    ),
                    const SizedBox(width: 7),
                    Text('What is excluded', style: theme.textTheme.titleSmall),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Headline time counts only activities with a valid logged duration and a classified work category. '
                  '${workload.missingDurationActivities} activities have no duration and ${workload.estimatedActivities} are estimated; '
                  '${workload.unknownCategoryActivities} are unclassified. None are treated as zero.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<ShareSegment> _segments(WorkloadMetrics workload, PulsePalette palette) {
    return [
      ShareSegment(
        label: 'Sales',
        value: workload.salesMinutes.toDouble(),
        color: palette.accent,
      ),
      ShareSegment(
        label: 'Operations',
        value: workload.operationsMinutes.toDouble(),
        color: palette.sky,
      ),
      ShareSegment(
        label: 'Other',
        value: workload.otherMinutes.toDouble(),
        color: palette.violet,
      ),
    ];
  }
}

class _SplitCard extends StatefulWidget {
  const _SplitCard({required this.bundle, required this.segments});

  final AnalyticsBundle bundle;
  final List<ShareSegment> segments;

  @override
  State<_SplitCard> createState() => _SplitCardState();
}

class _SplitCardState extends State<_SplitCard> {
  /// Segment order matches [_segments]: sales, operations, other.
  static const _categories = [
    WorkCategory.sales,
    WorkCategory.operations,
    WorkCategory.other,
  ];

  int? _selected;

  Future<void> _open(int index) async {
    PulseHaptics.selection();
    setState(() => _selected = index);
    final category = _categories[index];
    await showCategoryActivitiesSheet(
      context,
      category: category,
      activities: activitiesForCategory(widget.bundle.scope, category),
      dataset: widget.bundle.dataset,
    );
    if (mounted) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final workload = widget.bundle.workload;
    final segments = widget.segments;
    final theme = Theme.of(context);
    final palette = context.pulse;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Logged time split',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const MetricInfoButton(metricKey: 'opsShare', dense: true),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                workload.operationsShare == null
                    ? '—'
                    : formatPercent(workload.operationsShare!),
                style: AppTypography.numeric(
                  theme.textTheme.headlineLarge!,
                  size: 31,
                  color:
                      workload.operationsShare != null &&
                          workload.operationsShare! >= 0.3
                      ? palette.amber
                      : null,
                ),
              ),
              const SizedBox(width: 7),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('operations', style: theme.textTheme.bodySmall),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${formatMinutes(workload.totalMinutes)} logged across ${workload.validActivities} activities',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: 15),
          StackedShareBar(
            segments: segments,
            height: 14,
            selectedIndex: _selected,
            onSegmentTap: _open,
            semanticsSuffix: ' of logged time',
          ),
          const SizedBox(height: 10),
          ShareLegend(
            segments: segments,
            selectedIndex: _selected,
            onTap: _open,
          ),
          const SizedBox(height: 15),
          Divider(color: palette.border),
          const SizedBox(height: 10),
          _SplitRow(
            label: 'Sales',
            value: formatMinutes(workload.salesMinutes),
            share: workload.salesShare,
            color: palette.accent,
          ),
          const SizedBox(height: 7),
          _SplitRow(
            label: 'Operations',
            value: formatMinutes(workload.operationsMinutes),
            share: workload.operationsShare,
            color: palette.sky,
          ),
          const SizedBox(height: 7),
          _SplitRow(
            label: 'Other',
            value: formatMinutes(workload.otherMinutes),
            share: workload.otherShare,
            color: palette.violet,
          ),
          const SizedBox(height: 12),
          CoverageNote(
            text:
                'Coverage ${formatPercent(workload.coverage ?? 0)} of eligible activities. Estimated and missing durations are excluded from the headline.',
          ),
        ],
      ),
    );
  }
}

class _SplitRow extends StatelessWidget {
  const _SplitRow({
    required this.label,
    required this.value,
    required this.share,
    required this.color,
  });

  final String label;
  final String value;
  final double? share;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ),
        Text(
          value,
          style: AppTypography.numeric(
            theme.textTheme.labelMedium!,
            size: 11,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            share == null ? '—' : formatPercent(share!),
            textAlign: TextAlign.right,
            style: AppTypography.numeric(
              theme.textTheme.labelSmall!,
              size: 9.5,
              color: palette.textMuted,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.bundle});

  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Time trend', style: theme.textTheme.titleMedium),
              ),
              PulsePill(
                label: bundle.window.label,
                dense: true,
                color: palette.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Valid logged time per bucket',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: 14),
          WorkloadTrendChart(points: bundle.workload.trend),
        ],
      ),
    );
  }
}

class _SubcategoryRow extends StatelessWidget {
  const _SubcategoryRow({required this.item, required this.maxMinutes});

  final WorkloadSubcategoryBreakdown item;
  final int maxMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    return Row(
      children: [
        Icon(
          workCategoryIcon(item.category),
          size: 13,
          color: workCategoryColor(item.category, palette),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 98,
          child: Text(
            workSubcategoryLabel(item.subcategory),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textSecondary,
              fontSize: 10.5,
            ),
          ),
        ),
        Expanded(
          child: HBar(
            value: maxMinutes == 0 ? 0 : item.minutes / maxMinutes,
            color: workCategoryColor(item.category, palette),
            height: 5,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 42,
          child: Text(
            formatMinutes(item.minutes),
            textAlign: TextAlign.right,
            style: AppTypography.numeric(
              theme.textTheme.labelSmall!,
              size: 9.5,
              color: palette.textSecondary,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 32,
          child: Text(
            formatPercent(item.share),
            textAlign: TextAlign.right,
            style: AppTypography.numeric(
              theme.textTheme.labelSmall!,
              size: 9,
              color: palette.textMuted,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _RepWorkloadRow extends StatelessWidget {
  const _RepWorkloadRow({required this.rep, required this.topOperations});

  final RepWorkload rep;
  final bool topOperations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    return InkWell(
      onTap: () => context.push('/team/${rep.user.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            InitialsAvatar(
              name: rep.user.displayName,
              size: 34,
              highlight: topOperations,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          rep.user.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      if (topOperations) ...[
                        const SizedBox(width: 5),
                        PulsePill(
                          label: 'Top ops load',
                          dense: true,
                          color: palette.amber,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: HBar(
                          value: rep.operationsShare?.clamp(0.0, 1.0) ?? 0,
                          color:
                              rep.operationsShare != null &&
                                  rep.operationsShare! >= 0.3
                              ? palette.amber
                              : palette.sky,
                          height: 5,
                        ),
                      ),
                      const SizedBox(width: 7),
                      SizedBox(
                        width: 33,
                        child: Text(
                          rep.operationsShare == null
                              ? '—'
                              : formatPercent(rep.operationsShare!),
                          textAlign: TextAlign.right,
                          style: AppTypography.numeric(
                            theme.textTheme.labelSmall!,
                            size: 9.5,
                            color: palette.textSecondary,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${formatMinutes(rep.operationsMinutes)} ops · '
                    '${formatMinutes(rep.totalMinutes)} total · '
                    'coverage ${formatPercent(rep.coverage ?? 0)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: palette.textMuted,
                      fontSize: 8.5,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: palette.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
