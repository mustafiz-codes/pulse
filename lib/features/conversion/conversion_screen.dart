import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../core/analytics/conversion_metrics.dart';
import '../../core/data/providers.dart';
import '../../core/models/enums.dart';
import '../../core/models/sales_dataset.dart';
import '../../core/utils/currency_format.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/labels.dart';

class ConversionScreen extends ConsumerWidget {
  const ConversionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(analyticsBundleProvider);
    final conversion = bundle.conversion;
    final cohort = conversion.selectedCohort;
    final theme = Theme.of(context);

    return PulseDetailScaffold(
      title: 'Conversion analytics',
      subtitle: bundle.window.label,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          const AnalyticsFilterBar(),
          const SizedBox(height: 16),
          ResponsiveGrid(
            children: [
              KpiCard(
                label: 'Leads in cohort',
                value: AnimatedNumber(
                  value: cohort.totalLeads.toDouble(),
                  format: (value) => value.round().toString(),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 28,
                  ),
                ),
                footnote: 'created in ${bundle.window.label}',
                icon: Icons.person_add_alt_1_outlined,
              ),
              KpiCard(
                label: 'Lead → opportunity',
                metricKey: 'leadToOpportunity',
                value: AnimatedNumber(
                  value: (cohort.opportunityRate ?? 0) * 100,
                  format: (value) => cohort.opportunityRate == null
                      ? '—'
                      : '${value.toStringAsFixed(0)}%',
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 28,
                  ),
                ),
                footnote: '${cohort.opportunity} of ${cohort.totalLeads} leads',
              ),
              KpiCard(
                label: 'Lead → won',
                metricKey: 'leadConversion',
                value: AnimatedNumber(
                  value: (cohort.conversionRate ?? 0) * 100,
                  format: (value) => cohort.conversionRate == null
                      ? '—'
                      : '${value.toStringAsFixed(0)}%',
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 28,
                  ),
                ),
                footnote: cohort.provisional
                    ? 'provisional cohort · still maturing'
                    : '${cohort.won} won leads',
              ),
              KpiCard(
                label: 'Median first response',
                metricKey: 'firstResponse',
                value: AnimatedNumber(
                  value: conversion.medianFirstResponseHours ?? 0,
                  format: (value) => conversion.medianFirstResponseHours == null
                      ? 'Not recorded'
                      : formatDurationHours(value),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 28,
                  ),
                ),
                footnote:
                    '${conversion.firstResponseSample} of ${cohort.totalLeads} leads with a timestamp',
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final funnel = _FunnelCard(bundle: bundle);
              final dwell = _StageDwellCard(bundle: bundle);
              if (constraints.maxWidth < 760) {
                return Column(
                  children: [funnel, const SizedBox(height: 12), dwell],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: funnel),
                  const SizedBox(width: 12),
                  Expanded(flex: 6, child: dwell),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Cohort comparison',
            subtitle:
                'Recent leads against a matured cohort with 90+ days to convert',
          ),
          _CohortComparisonCard(bundle: bundle),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Stage entries recorded',
            subtitle: 'Recorded transitions inside the reporting window',
          ),
          _StageEntriesCard(bundle: bundle),
          const SizedBox(height: 16),
          CoverageNote(
            text:
                'Stage dwell is calculated from recorded stage-change events. '
                '${conversion.unavailableStageHistory} deals in this context have no usable stage history and are excluded from dwell calculations. '
                '${conversion.uncontactedLeads} leads have no first-contact timestamp and are never treated as zero.',
          ),
        ],
      ),
    );
  }
}

class _FunnelCard extends StatelessWidget {
  const _FunnelCard({required this.bundle});

  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    final cohort = bundle.conversion.selectedCohort;
    final total = cohort.totalLeads;
    final stages = [
      _FunnelStage(
        label: 'Leads',
        count: total,
        color: palette.sky,
        icon: Icons.person_add_alt_1_rounded,
      ),
      _FunnelStage(
        label: 'Contacted',
        count: cohort.contacted,
        color: palette.violet,
        icon: Icons.bolt_rounded,
      ),
      _FunnelStage(
        label: 'Qualified',
        count: cohort.qualified,
        color: palette.teal,
        icon: Icons.verified_outlined,
      ),
      _FunnelStage(
        label: 'Opportunity',
        count: cohort.opportunity,
        color: palette.amber,
        icon: Icons.work_outline_rounded,
      ),
      _FunnelStage(
        label: 'Won',
        count: cohort.won,
        color: palette.accent,
        icon: Icons.emoji_events_outlined,
      ),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Lead funnel', style: theme.textTheme.titleMedium),
              ),
              PulsePill(
                label: cohort.provisional ? 'Provisional' : 'Matured',
                dense: true,
                filled: true,
                color: cohort.provisional ? palette.amber : palette.positive,
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '${formatDate(cohort.start)} – ${formatDate(cohort.end)}',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < stages.length; i++) ...[
            _FunnelRow(
              stage: stages[i],
              total: total,
              previous: i == 0 ? null : stages[i - 1].count,
            ),
            if (i < stages.length - 1) const SizedBox(height: 13),
          ],
          const SizedBox(height: 14),
          Divider(color: palette.border),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _FunnelFootnote(
                  label: 'Opportunity → won',
                  value: cohort.opportunityToWinRate == null
                      ? '—'
                      : formatPercent(cohort.opportunityToWinRate!),
                ),
              ),
              Expanded(
                child: _FunnelFootnote(
                  label: 'Median lead → win',
                  value: cohort.medianLeadToWinDays == null
                      ? '—'
                      : formatDurationDays(cohort.medianLeadToWinDays!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FunnelStage {
  const _FunnelStage({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;
}

class _FunnelRow extends StatelessWidget {
  const _FunnelRow({
    required this.stage,
    required this.total,
    required this.previous,
  });

  final _FunnelStage stage;
  final int total;
  final int? previous;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    final share = total == 0 ? 0.0 : stage.count / total;
    final stepRate = previous == null || previous == 0
        ? null
        : stage.count / previous!;

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: stage.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: stage.color.withValues(alpha: 0.28)),
          ),
          child: Icon(stage.icon, size: 15, color: stage.color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      stage.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  Text(
                    '${stage.count}',
                    style: AppTypography.numeric(
                      theme.textTheme.titleSmall!,
                      size: 13,
                    ),
                  ),
                  const SizedBox(width: 5),
                  SizedBox(
                    width: 34,
                    child: Text(
                      total == 0 ? '—' : formatPercent(share),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.textMuted,
                        fontSize: 9,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              HBar(value: share, color: stage.color, height: 5),
              if (stepRate != null) ...[
                const SizedBox(height: 3),
                Text(
                  '${formatPercent(stepRate)} step conversion',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                    fontSize: 8.5,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FunnelFootnote extends StatelessWidget {
  const _FunnelFootnote({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: palette.textMuted,
            fontSize: 8,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.numeric(theme.textTheme.titleSmall!, size: 13),
        ),
      ],
    );
  }
}

class _StageDwellCard extends StatelessWidget {
  const _StageDwellCard({required this.bundle});

  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    final stats = [...bundle.conversion.stageDwells];
    final maxDays = stats.isEmpty
        ? 1.0
        : stats.map((stat) => stat.medianDays).reduce((a, b) => a > b ? a : b);
    final slowest = bundle.conversion.slowestStage;
    stats.sort((a, b) => _stageOrder(a.stage).compareTo(_stageOrder(b.stage)));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Stage dwell', style: theme.textTheme.titleMedium),
              ),
              const MetricInfoButton(metricKey: 'stageDwell', dense: true),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Median days per stage visit',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: 16),
          if (stats.isEmpty)
            Text(
              'No usable stage history in this filter context.',
              style: theme.textTheme.bodySmall,
            )
          else ...[
            for (var i = 0; i < stats.length; i++) ...[
              _DwellRow(
                stat: stats[i],
                maxDays: maxDays,
                isSlowest: slowest?.stage == stats[i].stage,
              ),
              if (i < stats.length - 1) const SizedBox(height: 12),
            ],
            const SizedBox(height: 15),
            if (slowest != null)
              InfoBanner(
                title: '${slowest.stage.label} is the slowest stage',
                message:
                    'Median ${formatDurationDays(slowest.medianDays)} across '
                    '${slowest.sampleCount} stage visits. This is an observation, not a causal claim.',
                color: palette.amber,
                icon: Icons.hourglass_bottom_rounded,
              ),
          ],
        ],
      ),
    );
  }

  int _stageOrder(DealStage stage) => switch (stage) {
    DealStage.newStage => 0,
    DealStage.qualified => 1,
    DealStage.discovery => 2,
    DealStage.proposal => 3,
    DealStage.negotiation => 4,
    DealStage.won => 5,
    DealStage.lost => 6,
  };
}

class _DwellRow extends StatelessWidget {
  const _DwellRow({
    required this.stat,
    required this.maxDays,
    required this.isSlowest,
  });

  final StageDwellStat stat;
  final double maxDays;
  final bool isSlowest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dealStageColor(stat.stage, palette),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Row(
                children: [
                  Text(
                    stat.stage.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: palette.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  if (isSlowest) ...[
                    const SizedBox(width: 5),
                    PulsePill(
                      label: 'Slowest',
                      dense: true,
                      color: palette.amber,
                    ),
                  ],
                ],
              ),
            ),
            Text(
              formatDurationDays(stat.medianDays),
              style: AppTypography.numeric(
                theme.textTheme.labelMedium!,
                size: 11.5,
                color: isSlowest ? palette.amber : palette.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        HBar(
          value: maxDays == 0 ? 0 : stat.medianDays / maxDays,
          color: isSlowest
              ? palette.amber
              : dealStageColor(stat.stage, palette).withValues(alpha: 0.7),
          height: 5,
        ),
        const SizedBox(height: 3),
        Text(
          '${stat.sampleCount} visits · ${stat.dealCount} deals · mean ${formatDurationDays(stat.meanDays)}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: palette.textMuted,
            fontSize: 8.5,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _CohortComparisonCard extends StatelessWidget {
  const _CohortComparisonCard({required this.bundle});

  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    final selected = bundle.conversion.selectedCohort;
    final matured = bundle.conversion.maturedCohort;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'METRIC',
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 8.5),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'SELECTED',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 8.5),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'MATURED',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 8.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          _ComparisonRow(
            label: 'Leads',
            selected: '${selected.totalLeads}',
            matured: '${matured.totalLeads}',
          ),
          _ComparisonRow(
            label: 'Contacted',
            selected: selected.contactedRate == null
                ? '—'
                : formatPercent(selected.contactedRate!),
            matured: matured.contactedRate == null
                ? '—'
                : formatPercent(matured.contactedRate!),
          ),
          _ComparisonRow(
            label: 'Qualified',
            selected: selected.qualifiedRate == null
                ? '—'
                : formatPercent(selected.qualifiedRate!),
            matured: matured.qualifiedRate == null
                ? '—'
                : formatPercent(matured.qualifiedRate!),
          ),
          _ComparisonRow(
            label: 'Opportunity',
            selected: selected.opportunityRate == null
                ? '—'
                : formatPercent(selected.opportunityRate!),
            matured: matured.opportunityRate == null
                ? '—'
                : formatPercent(matured.opportunityRate!),
          ),
          _ComparisonRow(
            label: 'Won',
            selected: selected.conversionRate == null
                ? '—'
                : formatPercent(selected.conversionRate!),
            matured: matured.conversionRate == null
                ? '—'
                : formatPercent(matured.conversionRate!),
            highlight: true,
          ),
          _ComparisonRow(
            label: 'Median lead → win',
            selected: selected.medianLeadToWinDays == null
                ? '—'
                : formatDurationDays(selected.medianLeadToWinDays!),
            matured: matured.medianLeadToWinDays == null
                ? '—'
                : formatDurationDays(matured.medianLeadToWinDays!),
            isLast: true,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: palette.textMuted,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  selected.provisional
                      ? 'The selected cohort is provisional: recent leads have not had the same time to mature as the 90+ day cohort.'
                      : 'The selected cohort has had at least 90 days to mature.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                    fontSize: 9.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.selected,
    required this.matured,
    this.highlight = false,
    this.isLast = false,
  });

  final String label;
  final String selected;
  final String matured;
  final bool highlight;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: palette.border, width: 0.7)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              selected,
              textAlign: TextAlign.right,
              style: AppTypography.numeric(
                theme.textTheme.labelMedium!,
                size: 11,
                color: highlight ? palette.accent : palette.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              matured,
              textAlign: TextAlign.right,
              style: AppTypography.numeric(
                theme.textTheme.labelMedium!,
                size: 11,
                color: palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageEntriesCard extends StatelessWidget {
  const _StageEntriesCard({required this.bundle});

  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    final counts = bundle.stageEnteredCounts;
    final total = counts.values.fold<int>(0, (sum, value) => sum + value);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$total recorded transitions',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              PulsePill(
                label: bundle.window.label,
                dense: true,
                color: palette.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Counts are stage-entry events, not deal counts. A deal can enter several stages in one period.',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 14),
          if (counts.isEmpty)
            Text(
              'No stage transitions were recorded in this window.',
              style: theme.textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final stage in SalesDataset.pipelineStages)
                  if ((counts[stage] ?? 0) > 0)
                    _StageCountChip(
                      stage: stage,
                      count: counts[stage]!,
                      color: dealStageColor(stage, palette),
                    ),
              ],
            ),
          const SizedBox(height: 12),
          Divider(color: palette.border),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Stage ageing is on the pipeline screen',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/pipeline'),
                child: const Text('Open pipeline'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageCountChip extends StatelessWidget {
  const _StageCountChip({
    required this.stage,
    required this.count,
    required this.color,
  });

  final DealStage stage;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stage.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 10,
              letterSpacing: 0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: AppTypography.numeric(
              Theme.of(context).textTheme.labelMedium!,
              size: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
