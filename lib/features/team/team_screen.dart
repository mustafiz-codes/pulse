import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/widgets/animated_reorder_column.dart';
import '../../app/widgets/app_card.dart';
import '../../app/widgets/filter_bar.dart';
import '../../app/widgets/layout.dart';
import '../../app/widgets/numbers.dart';
import '../../app/widgets/people.dart';
import '../../app/widgets/section.dart';
import '../../app/widgets/user_avatar.dart';
import '../../app/widgets/unit_tag.dart';
import '../../app/widgets/top_bar.dart';
import '../../core/analytics/team_metrics.dart';
import '../../core/data/providers.dart';
import '../../core/utils/currency_format.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/labels.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  RankingMode _mode = RankingMode.bookedSales;

  @override
  Widget build(BuildContext context) {
    final bundle = ref.watch(analyticsBundleProvider);
    final team = bundle.team;
    final theme = Theme.of(context);
    final palette = context.pulse;
    final ranked = team.ranked(_mode);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 30),
      children: [
        const PageTitle(title: 'Team performance'),
        const SizedBox(height: 14),
        const AnalyticsFilterBar(),
        const SizedBox(height: 16),
        ResponsiveGrid(
          children: [
            KpiCard(
              label: 'Team booked sales',
              metricKey: 'bookedSales',
              value: AnimatedNumber(
                value: team.totalBookedMinor / 100,
                format: (_) =>
                    formatMoneyMinor(team.totalBookedMinor, compact: true),
                style: AppTypography.numeric(
                  theme.textTheme.displaySmall!,
                  size: 28,
                ),
              ),
              footnote: '${team.totalWonDeals} won deals',
              icon: Icons.groups_rounded,
            ),
            KpiCard(
              label: 'Target attainment',
              metricKey: 'targetAttainment',
              value: AnimatedNumber(
                value: (team.attainment ?? 0) * 100,
                format: (value) => team.attainment == null
                    ? '—'
                    : '${value.toStringAsFixed(1)}%',
                style: AppTypography.numeric(
                  theme.textTheme.displaySmall!,
                  size: 28,
                ),
              ),
              footnote: team.totalTargetMinor == null
                  ? 'target unavailable'
                  : 'vs ${formatMoneyMinor(team.totalTargetMinor!, compact: true)} prorated',
            ),
            KpiCard(
              label: 'Closed-deal win rate',
              metricKey: 'winRate',
              value: AnimatedNumber(
                value: (team.winRate ?? 0) * 100,
                format: (value) =>
                    team.winRate == null ? '—' : '${value.toStringAsFixed(0)}%',
                style: AppTypography.numeric(
                  theme.textTheme.displaySmall!,
                  size: 28,
                ),
              ),
              footnote: '${team.totalClosedDeals} closed deals',
            ),
            KpiCard(
              label: 'Open pipeline',
              metricKey: 'openPipeline',
              value: AnimatedNumber(
                value: team.totalOpenPipelineMinor / 100,
                format: (_) => formatMoneyMinor(
                  team.totalOpenPipelineMinor,
                  compact: true,
                ),
                style: AppTypography.numeric(
                  theme.textTheme.displaySmall!,
                  size: 28,
                ),
              ),
              footnote: 'snapshot · not a forecast',
              icon: Icons.view_kanban_outlined,
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Rep ranking',
          subtitle:
              'Ranked by ${_mode.label.toLowerCase()} · tap for a full profile',
          action: PulsePill(
            label: '${ranked.length} reps',
            dense: true,
            filled: true,
            color: palette.textSecondary,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final mode in RankingMode.values) ...[
                FilterChipButton(
                  label: mode.label,
                  selected: _mode == mode,
                  onTap: () => setState(() => _mode = mode),
                ),
                if (mode != RankingMode.values.last) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (ranked.isEmpty)
          const EmptyState(
            title: 'No reps match',
            message: 'Try clearing the rep or unit filter.',
            icon: Icons.person_search_outlined,
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            // Fixed row extent lets ranking changes glide rows into their
            // new slot. 45 is the text column height at 1x; padding (22) and
            // the divider (1) do not scale. The factor comes from the row's
            // smallest text (10.5pt), which grows most under Android's
            // non-linear font scaling.
            child: AnimatedReorderColumn(
              ids: [for (final rep in ranked) rep.user.id],
              itemExtent:
                  26 +
                  45 * (MediaQuery.textScalerOf(context).scale(10.5) / 10.5) +
                  1,
              itemBuilder: (context, i) => Column(
                children: [
                  Expanded(
                    child: _RepRankRow(
                      rep: ranked[i],
                      rank: i + 1,
                      mode: _mode,
                      maxBookedMinor: ranked.first.bookedSalesMinor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Divider(
                      height: 1,
                      color: i < ranked.length - 1
                          ? palette.border
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        CoverageNote(
          text:
              'Win rate and cycle-time rankings place reps with fewer than 5 closed deals after those with larger samples. '
              'Targets are prorated for the selected dates; missing targets are never treated as zero.',
        ),
      ],
    );
  }
}

class _RepRankRow extends StatelessWidget {
  const _RepRankRow({
    required this.rep,
    required this.rank,
    required this.mode,
    required this.maxBookedMinor,
  });

  final RepPerformance rep;
  final int rank;
  final RankingMode mode;
  final int maxBookedMinor;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final theme = Theme.of(context);
    final (value, subvalue, tone) = _primaryMetric(palette);
    final lowSample =
        rep.lowSample &&
        (mode == RankingMode.winRate || mode == RankingMode.cycleTime);

    return InkWell(
      onTap: () => context.push('/team/${rep.user.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '$rank',
                style: AppTypography.numeric(
                  theme.textTheme.labelMedium!,
                  color: rank <= 3 ? palette.accent : palette.textMuted,
                  size: 11.5,
                ),
              ),
            ),
            UserAvatar(userId: rep.user.id, size: 38),
            const SizedBox(width: 10),
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
                      const SizedBox(width: 6),
                      Flexible(child: UnitTag(unitId: rep.user.homeUnitId)),
                      if (lowSample) ...[
                        const SizedBox(width: 6),
                        PulsePill(
                          label: 'Low sample',
                          dense: true,
                          color: palette.amber,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${jobRoleLabel(rep.user.jobRole)} · ${rep.closedDeals} closed',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
                  ),
                  if (mode == RankingMode.bookedSales) ...[
                    const SizedBox(height: 6),
                    HBar(
                      value: maxBookedMinor == 0
                          ? 0
                          : rep.bookedSalesMinor / maxBookedMinor,
                      color: rank == 1 ? palette.accent : palette.sky,
                      height: 4,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: AppTypography.numeric(
                    theme.textTheme.titleSmall!,
                    size: 13,
                    color: tone,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subvalue,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                    fontSize: 9,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 2),
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

  (String, String, Color?) _primaryMetric(PulsePalette palette) {
    return switch (mode) {
      RankingMode.bookedSales => (
        formatMoneyMinor(rep.bookedSalesMinor, compact: true),
        rep.targetAttainment == null
            ? 'no target'
            : '${(rep.targetAttainment! * 100).toStringAsFixed(0)}% of target',
        null,
      ),
      RankingMode.targetAttainment => (
        rep.targetAttainment == null
            ? '—'
            : '${(rep.targetAttainment! * 100).toStringAsFixed(0)}%',
        rep.targetAttainment == null
            ? 'target unavailable'
            : '${formatMoneyMinor(rep.bookedSalesMinor, compact: true)} booked',
        rep.targetAttainment != null && rep.targetAttainment! >= 1
            ? palette.positive
            : null,
      ),
      RankingMode.winRate => (
        rep.winRate == null ? '—' : formatPercent(rep.winRate!),
        '${rep.wonDeals} won / ${rep.closedDeals} closed',
        null,
      ),
      RankingMode.cycleTime => (
        rep.medianCycleDays == null
            ? '—'
            : formatDurationDays(rep.medianCycleDays!),
        '${rep.wonDeals} won deals',
        null,
      ),
    };
  }
}
