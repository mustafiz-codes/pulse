import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/feedback/haptics.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/widgets/app_card.dart';
import '../../app/widgets/filter_bar.dart';
import '../../app/widgets/layout.dart';
import '../../app/widgets/metric_info.dart';
import '../../app/widgets/numbers.dart';
import '../../app/widgets/people.dart';
import '../../app/widgets/section.dart';
import '../../app/widgets/user_avatar.dart';
import '../../app/widgets/unit_tag.dart';
import '../../core/analytics/analytics_bundle.dart';
import '../../core/analytics/insight_rules.dart';
import '../../core/analytics/needs_attention.dart';
import '../../core/analytics/reporting_filter.dart';
import '../../core/analytics/team_metrics.dart';
import '../../core/data/providers.dart';
import '../../core/models/enums.dart';
import '../../core/utils/currency_format.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/labels.dart';
import 'widgets/booked_target_chart.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(analyticsBundleProvider);
    final theme = Theme.of(context);
    final palette = context.pulse;

    // Pull-to-reset restores the default demo view. It is not a network
    // refresh: there is nothing to fetch, so no delay and no "updated" toast.
    return RefreshIndicator(
      semanticsLabel: 'Reset demo view',
      color: palette.accent,
      onRefresh: () async {
        PulseHaptics.confirm();
        ref.read(reportingFilterProvider.notifier).reset();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 2, 18, 30),
        children: [
          const PageTitle(title: 'Executive overview'),
          const SizedBox(height: 14),
          const AnalyticsFilterBar(),
          const SizedBox(height: 16),
          _HeroSalesCard(bundle: bundle),
          const SizedBox(height: 14),
          _KpiStrip(
            key: const ValueKey('overview-kpi-strip'),
            cards: [
              KpiCard(
                label: 'Win rate',
                metricKey: 'winRate',
                onTap: () => context.go('/pipeline'),
                value: AnimatedNumber(
                  value: (bundle.sales.winRate ?? 0) * 100,
                  format: (value) => bundle.sales.winRate == null
                      ? '—'
                      : '${value.toStringAsFixed(0)}%',
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 28,
                  ),
                ),
                delta: DeltaChip(
                  value: bundle.winRateDeltaPoints,
                  label: bundle.winRateDeltaPoints == null
                      ? 'No prior data'
                      : formatPercentagePoints(bundle.winRateDeltaPoints!),
                ),
                footnote: '${bundle.sales.closedDeals} closed deals',
              ),
              KpiCard(
                label: 'Median lead-to-win',
                metricKey: 'medianLeadToWin',
                onTap: () => context.push('/conversion'),
                value: AnimatedNumber(
                  value: bundle.sales.medianLeadToWinDays ?? 0,
                  format: (value) => bundle.sales.medianLeadToWinDays == null
                      ? '—'
                      : formatDurationDays(value),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 28,
                  ),
                ),
                delta: DeltaChip(
                  value: bundle.leadToWinDeltaDays,
                  label: bundle.leadToWinDeltaDays == null
                      ? 'No prior data'
                      : '${bundle.leadToWinDeltaDays! >= 0 ? '+' : '−'}'
                            '${bundle.leadToWinDeltaDays!.abs().toStringAsFixed(1)}d',
                  positiveIsGood: false,
                ),
                footnote:
                    '${bundle.sales.leadToWinSample} of ${bundle.sales.wonDeals} won deals',
              ),
              KpiCard(
                label: 'Open pipeline',
                metricKey: 'openPipeline',
                onTap: () => context.go('/pipeline'),
                value: AnimatedNumber(
                  value: bundle.sales.openPipelineMinor / 100,
                  format: (value) => formatMoneyMinor(
                    bundle.sales.openPipelineMinor,
                    compact: true,
                  ),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 28,
                  ),
                ),
                footnote:
                    '${bundle.sales.openDealsCount} open deals · snapshot',
                icon: Icons.view_kanban_outlined,
              ),
              KpiCard(
                label: 'Target attainment',
                metricKey: 'targetAttainment',
                onTap: () => context.go('/team'),
                value: AnimatedNumber(
                  value: (bundle.sales.targetAttainment ?? 0) * 100,
                  format: (value) => bundle.sales.targetAttainment == null
                      ? '—'
                      : '${value.toStringAsFixed(1)}%',
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 28,
                  ),
                ),
                delta: DeltaChip(
                  value: bundle.attainmentDeltaPoints,
                  label: bundle.attainmentDeltaPoints == null
                      ? 'No prior target'
                      : formatPercentagePoints(bundle.attainmentDeltaPoints!),
                ),
                footnote: bundle.sales.targetCoverage.hasPartialCoverage
                    ? 'Partial target coverage'
                    : 'vs prorated target',
              ),
              KpiCard(
                label: 'Stalled',
                metricKey: 'stalledDeal',
                onTap: () => context.go('/pipeline'),
                value: AnimatedNumber(
                  value: bundle.sales.stalledDeals.toDouble(),
                  format: (value) => value.round().toString(),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 28,
                  ),
                ),
                footnote: 'open deals > 14 days in stage',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TopPerformersCard(bundle: bundle),
          const SizedBox(height: 14),
          _ByUnitCard(bundle: bundle),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Booked sales vs target',
                  subtitle: 'Won-deal value by close month, Europe/London',
                  padding: EdgeInsets.only(bottom: 14),
                ),
                BookedTargetChart(points: bundle.monthlySeries),
                const SizedBox(height: 12),
                CoverageNote(
                  text:
                      bundle.monthlySeries.any(
                        (point) => point.missingTargets > 0,
                      )
                      ? 'Targets are prorated monthly. Some owner-month targets are unavailable and are not assumed to be zero.'
                      : 'Targets are prorated to the reporting window. Booked value is not recognised revenue.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ResponsivePair(
            left: _ConversionBottleneckCard(bundle: bundle),
            right: _WorkloadCard(bundle: bundle),
          ),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'What stands out',
            subtitle: 'Deterministic rules over the same filtered records',
            action: Text(
              '${bundle.insights.length} signals',
              style: theme.textTheme.labelSmall?.copyWith(
                color: palette.textMuted,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (bundle.insights.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No rule-based insight crosses its threshold in this filter context.',
                style: theme.textTheme.bodySmall,
              ),
            )
          else
            for (final insight in bundle.insights) ...[
              _InsightCard(insight: insight),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 12),
          SectionHeader(
            title: 'Needs attention',
            subtitle: 'Rule-driven review flags, not proof of risk',
            action: TextButton(
              onPressed: () => context.go('/pipeline'),
              child: const Text('Pipeline'),
            ),
          ),
          _AttentionCard(items: bundle.attention),
          const SizedBox(height: 20),
          _ProvenanceCard(bundle: bundle),
        ],
      ),
    );
  }
}

/// Floating white hero card: booked sales, delta and won pills, and a thin
/// target bar (or "No unit targets" when a unit filter is active).
class _HeroSalesCard extends StatelessWidget {
  const _HeroSalesCard({required this.bundle});

  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final theme = Theme.of(context);
    final attainment = bundle.sales.targetAttainment;
    final target = bundle.sales.targetMinor;
    final unitFiltered = bundle.sales.targetCoverage.unitFiltered;
    final pct = attainment == null
        ? null
        : '${(attainment * 100).toStringAsFixed(1)}%';
    final targetLabel = unitFiltered
        ? 'No unit targets'
        : pct == null
        ? 'Target unavailable'
        : '$pct of target';

    return AppCard(
      key: const ValueKey('overview-hero'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      radius: 20,
      shadow: [
        BoxShadow(
          color: palette.accent.withValues(alpha: 0.12),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Booked sales · ${bundle.window.label}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              const MetricInfoButton(metricKey: 'bookedSales', dense: true),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AnimatedNumber(
              value: bundle.sales.bookedSalesMinor / 100,
              format: (_) => formatMoneyMinor(bundle.sales.bookedSalesMinor),
              style: AppTypography.numeric(
                theme.textTheme.displayLarge!,
                size: 38,
                letterSpacing: -1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DeltaChip(
                value: bundle.bookedSalesDeltaRate,
                label: bundle.previousSales.bookedSalesMinor == 0
                    ? 'No prior period'
                    : '${formatMoneyMinorSigned(bundle.bookedSalesDeltaMinor, compact: true)} vs previous',
              ),
              PulsePill(
                label: '${bundle.sales.wonDeals} won deals',
                color: palette.accent,
                filled: true,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            container: true,
            label: targetLabel,
            excludeSemantics: true,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: unitFiltered ? 0 : (attainment ?? 0).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: palette.surfaceAlt,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        targetLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.textMuted,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    if (!unitFiltered && target != null)
                      Text(
                        formatMoneyMinor(target, compact: true),
                        style: AppTypography.numeric(
                          theme.textTheme.labelSmall!,
                          weight: FontWeight.w600,
                        ).copyWith(color: palette.textSecondary),
                      ),
                  ],
                ),
                if (bundle.sales.targetCoverage.hasPartialCoverage) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Partial target coverage',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.amber,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Won-deal value, not recognised accounting revenue.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textMuted,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Swipeable row of small KPI cards; a partly visible next card hints that it
/// scrolls.
class _KpiStrip extends StatelessWidget {
  const _KpiStrip({super.key, required this.cards});

  final List<Widget> cards;

  static const double cardWidth = 168;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Key metrics, swipe for more',
      container: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                SizedBox(width: cardWidth, child: cards[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Top three reps by booked value, with avatars and home-unit tags.
class _TopPerformersCard extends StatelessWidget {
  const _TopPerformersCard({required this.bundle});

  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    final ranked = bundle.team.ranked(RankingMode.bookedSales).take(3).toList();
    return AppCard(
      key: const ValueKey('overview-top-performers'),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Top performers',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/team'),
                child: const Text('See all'),
              ),
            ],
          ),
          if (ranked.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 8, 10),
              child: Text(
                'No reps in this view.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          for (var i = 0; i < ranked.length; i++)
            InkWell(
              onTap: () => context.push('/team/${ranked[i].user.id}'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.fromLTRB(0, 6, 8, 6),
                decoration: BoxDecoration(
                  border: i < ranked.length - 1
                      ? Border(bottom: BorderSide(color: palette.border))
                      : null,
                ),
                child: Row(
                  children: [
                    UserAvatar(userId: ranked[i].user.id, size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              ranked[i].user.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: UnitTag(unitId: ranked[i].user.homeUnitId),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatMoneyMinor(
                        ranked[i].bookedSalesMinor,
                        compact: true,
                      ),
                      style: AppTypography.numeric(
                        theme.textTheme.bodyMedium!,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Booked sales split across the five units; tapping one opens Unit detail.
class _ByUnitCard extends StatelessWidget {
  const _ByUnitCard({required this.bundle});

  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    final units = bundle.units;
    final selected = bundle.filter.unitId == null
        ? null
        : units.indexWhere((u) => u.unitId == bundle.filter.unitId);
    final segments = [
      for (var i = 0; i < units.length; i++)
        ShareSegment(
          label: units[i].label,
          value: units[i].bookedMinor.toDouble(),
          color: palette.unitColors[i % palette.unitColors.length],
          detail: formatMoneyMinor(units[i].bookedMinor, compact: true),
        ),
    ];
    void open(int i) {
      PulseHaptics.selection();
      context.push('/units/${units[i].unitId}');
    }

    return AppCard(
      key: const ValueKey('overview-by-unit'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('By unit', style: theme.textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(
            'Booked sales · ${bundle.window.label}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          StackedShareBar(
            segments: segments,
            selectedIndex: selected,
            onSegmentTap: open,
            semanticsSuffix: ' of booked sales',
          ),
          const SizedBox(height: 10),
          ShareLegend(segments: segments, selectedIndex: selected, onTap: open),
        ],
      ),
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Phones stack; tablets (content capped at 720px) sit side by side.
        if (constraints.maxWidth < 640) {
          return Column(children: [left, const SizedBox(height: 12), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _ConversionBottleneckCard extends StatelessWidget {
  const _ConversionBottleneckCard({required this.bundle});

  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final theme = Theme.of(context);
    final slowest = bundle.conversion.slowestStage;
    final dwells = [...bundle.conversion.stageDwells]
      ..sort((a, b) => b.medianDays.compareTo(a.medianDays));
    final maxDays = dwells.isEmpty ? 1.0 : dwells.first.medianDays;

    return AppCard(
      onTap: () => context.push('/conversion'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Conversion bottleneck',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: palette.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (slowest == null)
            Text(
              'Stage history unavailable for this filter.',
              style: theme.textTheme.bodySmall,
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  slowest.stage.label,
                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    formatDurationDays(slowest.medianDays),
                    style: AppTypography.numeric(
                      theme.textTheme.titleMedium!,
                      color: palette.amber,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Median stage dwell · ${slowest.sampleCount} visits',
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textMuted,
                fontSize: 10.5,
              ),
            ),
            const SizedBox(height: 14),
            for (final stat in dwells.take(4)) ...[
              Row(
                children: [
                  SizedBox(
                    width: 74,
                    child: Text(
                      stat.stage.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.textSecondary,
                        fontSize: 10,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: HBar(
                      value: maxDays == 0 ? 0 : stat.medianDays / maxDays,
                      color: stat.stage == slowest.stage
                          ? palette.amber
                          : palette.sky.withValues(alpha: 0.6),
                      height: 5,
                    ),
                  ),
                  const SizedBox(width: 7),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${stat.medianDays.toStringAsFixed(1)}d',
                      textAlign: TextAlign.right,
                      style: AppTypography.numeric(
                        theme.textTheme.labelSmall!,
                        color: palette.textSecondary,
                        size: 9.5,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
            ],
          ],
          const SizedBox(height: 5),
          Divider(color: palette.border),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Text(
                  bundle.conversion.medianFirstResponseHours == null
                      ? 'First response not recorded'
                      : 'First response ${formatDurationHours(bundle.conversion.medianFirstResponseHours!)}',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
                ),
              ),
              Text(
                '${bundle.conversion.uncontactedLeads} uncontacted',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.amber,
                  fontSize: 9.5,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkloadCard extends StatelessWidget {
  const _WorkloadCard({required this.bundle});

  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final theme = Theme.of(context);
    final workload = bundle.workload;
    final categories = workload.categories;
    final segments = [
      ShareSegment(
        label: 'Sales',
        value: categories
            .firstWhere((item) => item.category == WorkCategory.sales)
            .minutes
            .toDouble(),
        color: palette.accent,
      ),
      ShareSegment(
        label: 'Operations',
        value: categories
            .firstWhere((item) => item.category == WorkCategory.operations)
            .minutes
            .toDouble(),
        color: palette.sky,
      ),
      ShareSegment(
        label: 'Other',
        value: categories
            .firstWhere((item) => item.category == WorkCategory.other)
            .minutes
            .toDouble(),
        color: palette.violet,
      ),
    ];
    final topRep = workload.topOperationsRep;

    return AppCard(
      onTap: () => context.push('/workload'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sales vs operations',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: palette.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (workload.insufficient)
            Text(
              'Insufficient logged time in this period.',
              style: theme.textTheme.bodySmall,
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatPercent(workload.operationsShare ?? 0),
                  style: AppTypography.numeric(
                    theme.textTheme.headlineMedium!,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 7),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    'operations',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Share of logged activity time · ${formatMinutes(workload.totalMinutes)} total',
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textMuted,
                fontSize: 10.5,
              ),
            ),
            const SizedBox(height: 14),
            StackedShareBar(
              segments: segments,
              height: 12,
              semanticsSuffix: ' of logged time',
            ),
            const SizedBox(height: 9),
            ShareLegend(segments: segments),
            const SizedBox(height: 14),
            Divider(color: palette.border),
            const SizedBox(height: 9),
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 14,
                  color: palette.textMuted,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    topRep == null
                        ? 'No operations time logged'
                        : 'Top ops load: ${topRep.user.displayName} · ${formatPercent(topRep.operationsShare ?? 0)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          CoverageNote(
            text:
                'Coverage ${formatPercent(workload.coverage ?? 0)} · ${workload.missingDurationActivities} activities have no duration and are not counted as zero.',
            tone: palette.textMuted,
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final theme = Theme.of(context);
    final tone = switch (insight.tone) {
      InsightTone.attention => palette.amber,
      InsightTone.positive => palette.positive,
      InsightTone.neutral => palette.sky,
    };
    final icon = switch (insight.tone) {
      InsightTone.attention => Icons.trending_up_rounded,
      InsightTone.positive => Icons.trending_down_rounded,
      InsightTone.neutral => Icons.insights_outlined,
    };
    return AppCard(
      padding: const EdgeInsets.all(15),
      onTap: () => context.push(insight.route),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tone.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, size: 16, color: tone),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  insight.body,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 17, color: palette.textMuted),
        ],
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.items});

  final List<AttentionItem> items;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    if (items.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 18,
              color: palette.positive,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Nothing crosses the attention rules in this filter context.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _AttentionRow(item: items[i]),
            if (i < items.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: palette.border),
              ),
          ],
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.item});

  final AttentionItem item;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final theme = Theme.of(context);
    final (icon, tone) = switch (item.type) {
      AttentionType.stalledDeal => (
        Icons.hourglass_bottom_rounded,
        palette.amber,
      ),
      AttentionType.overdueFollowUp => (Icons.schedule_rounded, palette.coral),
      AttentionType.uncontactedLead => (Icons.person_off_outlined, palette.sky),
    };
    return InkWell(
      onTap: () => context.push(item.route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 15, color: tone),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 1),
                  Text(item.subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 17,
              color: palette.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProvenanceCard extends StatelessWidget {
  const _ProvenanceCard({required this.bundle});

  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dataset_outlined, size: 14, color: palette.textMuted),
              const SizedBox(width: 6),
              Text(
                '${bundle.dataset.manifest.datasetLabel} · ${bundle.dataset.manifest.datasetId}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: palette.textSecondary,
                  fontSize: 9.5,
                  letterSpacing: 0.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Synthetic CRM-style fixture · as of ${formatDateTime(bundle.dataset.manifest.asOf)} · '
            '${bundle.dataset.manifest.timezone}. Read-only demo. No monday.com connection, network requests or saved edits.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textMuted,
              fontSize: 10,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
