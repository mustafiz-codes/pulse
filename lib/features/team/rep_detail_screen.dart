import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell/pulse_shell.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/semantic_colors.dart';
import '../../app/widgets/app_card.dart';
import '../../app/widgets/layout.dart';
import '../../app/widgets/numbers.dart';
import '../../app/widgets/people.dart';
import '../../app/widgets/section.dart';
import '../../app/widgets/unit_tag.dart';
import '../../app/widgets/user_avatar.dart';
import '../../core/analytics/analytics_bundle.dart';
import '../../core/analytics/team_metrics.dart';
import '../../core/data/providers.dart';
import '../../core/models/deal.dart';
import '../../core/models/lead.dart';
import '../../core/utils/currency_format.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/labels.dart';

class RepDetailScreen extends ConsumerWidget {
  const RepDetailScreen({super.key, required this.repId});

  final String repId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundle = ref.watch(analyticsBundleProvider);
    final user = bundle.dataset.usersById[repId];
    final rep = _findRep(bundle.team.reps, repId);
    final theme = Theme.of(context);
    final palette = context.pulse;

    if (user == null) {
      return PulseDetailScaffold(
        title: 'Rep not found',
        child: Center(
          child: Text(
            'No rep exists with id $repId.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }
    if (rep == null) {
      return PulseDetailScaffold(
        title: user.displayName,
        subtitle: 'Outside the current filter context',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'This person is excluded by the current rep or unit filter. '
              'Clear the filter to see their performance.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    final closedDeals =
        bundle.scope.dealsClosedInWindow
            .where((deal) => deal.ownerId == repId)
            .toList()
          ..sort((a, b) => b.closedAt!.compareTo(a.closedAt!));
    final openDeals =
        bundle.scope.openDealsSnapshot
            .where((deal) => deal.ownerId == repId)
            .toList()
          ..sort((a, b) => b.valueMinor.compareTo(a.valueMinor));
    final leads =
        bundle.scope.leadsCreatedInWindow
            .where((lead) => lead.ownerId == repId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return PulseDetailScaffold(
      title: user.displayName,
      subtitle: '${jobRoleLabel(user.jobRole)} · ${unitLabel(user.homeUnitId)}',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          AppCard(
            padding: const EdgeInsets.all(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                palette.accent.withValues(alpha: palette.isDark ? 0.14 : 0.09),
                palette.surface,
              ],
            ),
            borderColor: palette.accent.withValues(alpha: 0.25),
            child: Row(
              children: [
                UserAvatar(userId: user.id, size: 58),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        jobRoleLabel(user.jobRole),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      UnitTag(unitId: user.homeUnitId),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          PulsePill(
                            label: user.active ? 'Active' : 'Inactive',
                            dense: true,
                            filled: true,
                            color: user.active
                                ? palette.positive
                                : palette.textMuted,
                          ),
                          PulsePill(
                            label: '${rep.closedDeals} closed',
                            dense: true,
                            color: palette.textSecondary,
                          ),
                          if (rep.lowSample)
                            PulsePill(
                              label: 'Low sample',
                              dense: true,
                              color: palette.amber,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ResponsiveGrid(
            minItemWidth: 140,
            children: [
              KpiCard(
                label: 'Booked sales',
                metricKey: 'bookedSales',
                value: AnimatedNumber(
                  value: rep.bookedSalesMinor / 100,
                  format: (_) =>
                      formatMoneyMinor(rep.bookedSalesMinor, compact: true),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 24,
                  ),
                ),
                footnote: '${rep.wonDeals} won deals',
              ),
              KpiCard(
                label: 'Target attainment',
                metricKey: 'targetAttainment',
                value: Text(
                  rep.targetAttainment == null
                      ? '—'
                      : '${(rep.targetAttainment! * 100).toStringAsFixed(0)}%',
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 24,
                    color:
                        rep.targetAttainment != null &&
                            rep.targetAttainment! >= 1
                        ? palette.positive
                        : null,
                  ),
                ),
                footnote: rep.targetMinor == null
                    ? 'target unavailable'
                    : 'of ${formatMoneyMinor(rep.targetMinor!, compact: true)}',
              ),
              KpiCard(
                label: 'Win rate',
                metricKey: 'winRate',
                value: Text(
                  rep.winRate == null ? '—' : formatPercent(rep.winRate!),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 24,
                  ),
                ),
                footnote: '${rep.wonDeals} won / ${rep.closedDeals} closed',
              ),
              KpiCard(
                label: 'Median cycle',
                metricKey: 'medianDealCycle',
                value: Text(
                  rep.medianCycleDays == null
                      ? '—'
                      : formatDurationDays(rep.medianCycleDays!),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 24,
                  ),
                ),
                footnote: 'won deals · creation to close',
              ),
              KpiCard(
                label: 'Open pipeline',
                metricKey: 'openPipeline',
                value: Text(
                  formatMoneyMinor(rep.openPipelineMinor, compact: true),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 24,
                  ),
                ),
                footnote: 'snapshot · not a forecast',
              ),
              KpiCard(
                label: 'Leads allocated',
                value: Text(
                  '${rep.leadsAllocated}',
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 24,
                  ),
                ),
                footnote: 'created in period',
              ),
              KpiCard(
                label: 'Logged time',
                value: Text(
                  formatMinutes(rep.loggedMinutes),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 24,
                  ),
                ),
                footnote: '${rep.activitiesLogged} valid activities',
              ),
              KpiCard(
                label: 'Operations share',
                metricKey: 'opsShare',
                value: Text(
                  rep.operationsShare == null
                      ? '—'
                      : formatPercent(rep.operationsShare!),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 24,
                    color:
                        rep.operationsShare != null &&
                            rep.operationsShare! >= 0.3
                        ? palette.amber
                        : null,
                  ),
                ),
                footnote: 'of logged activity time',
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Target and workload',
            subtitle: 'Coverage is disclosed, not assumed',
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final targetCard = _TargetCard(rep: rep);
              final workloadCard = _RepWorkloadCard(rep: rep);
              if (constraints.maxWidth < 700) {
                return Column(
                  children: [
                    targetCard,
                    const SizedBox(height: 10),
                    workloadCard,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: targetCard),
                  const SizedBox(width: 10),
                  Expanded(child: workloadCard),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Closed deals',
            subtitle:
                '${closedDeals.length} won or lost in ${bundle.window.label}',
            action: PulsePill(
              label: formatMoneyMinor(rep.bookedSalesMinor, compact: true),
              dense: true,
              filled: true,
              color: palette.accent,
            ),
          ),
          if (closedDeals.isEmpty)
            const EmptyState(
              title: 'No closed deals in period',
              message: 'This rep did not close a deal in the selected window.',
              icon: Icons.emoji_events_outlined,
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < closedDeals.length; i++) ...[
                    _DealRow(
                      deal: closedDeals[i],
                      bundle: bundle,
                      closed: true,
                    ),
                    if (i < closedDeals.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Divider(color: palette.border),
                      ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Open pipeline',
            subtitle: '${openDeals.length} open deals · current snapshot',
          ),
          if (openDeals.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No open deals for this rep in the current context.',
                style: theme.textTheme.bodySmall,
              ),
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < openDeals.length; i++) ...[
                    _DealRow(deal: openDeals[i], bundle: bundle, closed: false),
                    if (i < openDeals.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Divider(color: palette.border),
                      ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Leads allocated',
            subtitle: '${leads.length} leads created in the selected window',
          ),
          if (leads.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No leads were created for this rep in the period.',
                style: theme.textTheme.bodySmall,
              ),
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < leads.take(6).length; i++) ...[
                    _LeadRow(lead: leads[i], bundle: bundle),
                    if (i < leads.take(6).length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Divider(color: palette.border),
                      ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
          CoverageNote(
            text:
                'Rep metrics use the same filter context as every other screen. Logged-time coverage is '
                '${formatPercent(rep.coverage ?? 0)} of eligible activities. Missing durations are not counted as zero.',
          ),
        ],
      ),
    );
  }

  RepPerformance? _findRep(List<RepPerformance> reps, String id) {
    for (final rep in reps) {
      if (rep.user.id == id) return rep;
    }
    return null;
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.rep});

  final RepPerformance rep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    final attainment = rep.targetAttainment;
    final coverage = rep.targetCoverage;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Target progress', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              ProgressRing(
                value: attainment?.clamp(0.0, 1.0),
                semanticLabel: attainment == null
                    ? 'Target unavailable'
                    : '${(attainment * 100).toStringAsFixed(0)}% of target',
                size: 84,
                strokeWidth: 7,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      attainment == null
                          ? '—'
                          : '${(attainment * 100).toStringAsFixed(0)}%',
                      style: AppTypography.numeric(
                        theme.textTheme.titleMedium!,
                        size: 17,
                      ),
                    ),
                    Text(
                      'of target',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.textMuted,
                        fontSize: 8,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rep.targetMinor == null
                          ? 'Target unavailable'
                          : formatMoneyMinor(rep.targetMinor!, compact: true),
                      style: AppTypography.numeric(
                        theme.textTheme.titleMedium!,
                        size: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'prorated target',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${formatMoneyMinor(rep.bookedSalesMinor, compact: true)} booked',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (coverage.hasPartialCoverage) ...[
            const SizedBox(height: 10),
            CoverageNote(
              text:
                  'Partial target coverage: ${coverage.includedOwnerMonths} owner-month target(s) present, '
                  '${coverage.missingOwnerMonths} missing. Missing targets are excluded.',
              tone: palette.amber,
            ),
          ],
        ],
      ),
    );
  }
}

class _RepWorkloadCard extends StatelessWidget {
  const _RepWorkloadCard({required this.rep});

  final RepPerformance rep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    final segments = [
      ShareSegment(
        label: 'Sales',
        value: rep.salesMinutes.toDouble(),
        color: palette.accent,
      ),
      ShareSegment(
        label: 'Operations',
        value: rep.operationsMinutes.toDouble(),
        color: palette.sky,
      ),
      ShareSegment(
        label: 'Other',
        value: rep.otherMinutes.toDouble(),
        color: palette.violet,
      ),
    ];
    final hasTime = rep.loggedMinutes > 0;

    return AppCard(
      onTap: () => context.push('/workload'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Logged workload',
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
          const SizedBox(height: 12),
          if (!hasTime)
            Text(
              'No valid logged time for this rep in the period.',
              style: theme.textTheme.bodySmall,
            )
          else ...[
            Text(
              rep.operationsShare == null
                  ? '—'
                  : formatPercent(rep.operationsShare!),
              style: AppTypography.numeric(
                theme.textTheme.headlineMedium!,
                size: 25,
                color:
                    rep.operationsShare != null && rep.operationsShare! >= 0.3
                    ? palette.amber
                    : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'operations · ${formatMinutes(rep.loggedMinutes)} logged',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
            ),
            const SizedBox(height: 13),
            StackedShareBar(
              segments: segments,
              height: 11,
              semanticsSuffix: ' of logged time',
            ),
            const SizedBox(height: 8),
            ShareLegend(segments: segments),
          ],
          const SizedBox(height: 11),
          Divider(color: palette.border),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.fact_check_outlined,
                size: 13,
                color: palette.textMuted,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Coverage ${formatPercent(rep.coverage ?? 0)} · ${rep.activitiesLogged} valid activities',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DealRow extends StatelessWidget {
  const _DealRow({
    required this.deal,
    required this.bundle,
    required this.closed,
  });

  final Deal deal;
  final AnalyticsBundle bundle;
  final bool closed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    final account = bundle.dataset.accountsById[deal.accountId];
    final stageColor = dealStageColor(deal.stage, palette);

    return InkWell(
      onTap: () => context.push('/deals/${deal.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          account?.name ?? 'Unknown account',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(width: 6),
                      PulsePill(
                        label: deal.stage.label,
                        dense: true,
                        filled: true,
                        color: stageColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    closed && deal.closedAt != null
                        ? 'Closed ${formatDate(deal.closedAt!)} · ${deal.title}'
                        : '${deal.title} · created ${formatDate(deal.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatMoneyMinor(deal.valueMinor, compact: true),
              style: AppTypography.numeric(
                theme.textTheme.titleSmall!,
                size: 12.5,
              ),
            ),
            const SizedBox(width: 2),
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

class _LeadRow extends StatelessWidget {
  const _LeadRow({required this.lead, required this.bundle});

  final Lead lead;
  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    final account = bundle.dataset.accountsById[lead.accountId];
    final statusColor = leadStatusColor(lead.status, palette);

    return InkWell(
      onTap: () => context.push('/leads/${lead.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              leadSourceIcon(lead.source),
              size: 15,
              color: palette.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          account?.name ?? 'Unknown account',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(width: 6),
                      PulsePill(
                        label: lead.status.label,
                        dense: true,
                        filled: true,
                        color: statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${lead.source.label} · created ${formatDate(lead.createdAt)}'
                    '${lead.firstContactedAt == null ? ' · first contact not recorded' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
                  ),
                ],
              ),
            ),
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
