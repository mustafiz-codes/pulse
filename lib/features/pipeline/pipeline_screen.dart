import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/semantic_colors.dart';
import '../../app/widgets/app_card.dart';
import '../../app/widgets/entrance_fade.dart';
import '../../app/widgets/filter_bar.dart';
import '../../app/widgets/hero_tags.dart';
import '../../app/widgets/layout.dart';
import '../../app/widgets/numbers.dart';
import '../../app/widgets/people.dart';
import '../../app/widgets/section.dart';
import '../../app/widgets/user_avatar.dart';
import '../../app/widgets/unit_tag.dart';
import '../../core/analytics/analytics_bundle.dart';
import '../../core/analytics/math_utils.dart';
import '../../core/data/providers.dart';
import '../../core/models/deal.dart';
import '../../core/models/enums.dart';
import '../../core/utils/currency_format.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/labels.dart';

class PipelineScreen extends ConsumerStatefulWidget {
  const PipelineScreen({super.key});

  @override
  ConsumerState<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends ConsumerState<PipelineScreen> {
  DealStage? _stage;

  @override
  Widget build(BuildContext context) {
    final bundle = ref.watch(analyticsBundleProvider);
    final theme = Theme.of(context);
    final palette = context.pulse;
    final openDeals = bundle.scope.openDealsSnapshot.toList()
      ..sort((a, b) => b.valueMinor.compareTo(a.valueMinor));
    final filtered = _stage == null
        ? openDeals
        : openDeals.where((deal) => deal.stage == _stage).toList();
    final stalledCount = openDeals
        .where((deal) => _isStalled(bundle, deal))
        .length;
    final medianAge = median(openDeals.map(bundle.scope.stageAgeDays));
    final missingHistory = openDeals
        .where((deal) => bundle.dataset.stageEventsFor(deal.id).isEmpty)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 30),
      children: [
        const PageTitle(title: 'Sales pipeline'),
        const SizedBox(height: 14),
        const AnalyticsFilterBar(),
        const SizedBox(height: 16),
        ResponsiveGrid(
          children: [
            KpiCard(
              label: 'Open pipeline',
              metricKey: 'openPipeline',
              value: AnimatedNumber(
                value: bundle.sales.openPipelineMinor / 100,
                format: (_) => formatMoneyMinor(
                  bundle.sales.openPipelineMinor,
                  compact: true,
                ),
                style: AppTypography.numeric(
                  theme.textTheme.displaySmall!,
                  size: 28,
                ),
              ),
              footnote: '${bundle.sales.openDealsCount} open deals',
              icon: Icons.account_balance_wallet_outlined,
            ),
            KpiCard(
              label: 'Open deals',
              value: AnimatedNumber(
                value: openDeals.length.toDouble(),
                format: (value) => value.round().toString(),
                style: AppTypography.numeric(
                  theme.textTheme.displaySmall!,
                  size: 28,
                ),
              ),
              footnote: 'after rep, unit and source filters',
              icon: Icons.view_kanban_outlined,
            ),
            KpiCard(
              label: 'Stalled deals',
              metricKey: 'stalledDeal',
              value: AnimatedNumber(
                value: stalledCount.toDouble(),
                format: (value) => value.round().toString(),
                style: AppTypography.numeric(
                  theme.textTheme.displaySmall!,
                  size: 28,
                  color: stalledCount > 0 ? palette.amber : null,
                ),
              ),
              footnote: '> 14 days in stage or inactive',
              icon: Icons.hourglass_bottom_rounded,
              accentColor: palette.amber,
            ),
            KpiCard(
              label: 'Median stage age',
              value: Text(
                medianAge == null ? '—' : formatDurationDays(medianAge),
                style: AppTypography.numeric(
                  theme.textTheme.displaySmall!,
                  size: 25,
                ),
              ),
              footnote: 'open deals, current stage',
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Stage distribution',
          subtitle: 'Select a stage to filter the deal list',
          action: PulsePill(
            label: '${openDeals.length} open',
            dense: true,
            filled: true,
            color: palette.sky,
          ),
        ),
        SizedBox(
          height: 106,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _StageCard(
                label: 'All open',
                count: openDeals.length,
                valueMinor: bundle.sales.openPipelineMinor,
                selected: _stage == null,
                color: palette.accent,
                onTap: () => setState(() => _stage = null),
              ),
              for (final stage in SalesDatasetStages.pipeline)
                _StageCard(
                  label: stage.label,
                  count: openDeals.where((deal) => deal.stage == stage).length,
                  valueMinor: openDeals
                      .where((deal) => deal.stage == stage)
                      .fold<int>(0, (sum, deal) => sum + deal.valueMinor),
                  selected: _stage == stage,
                  color: dealStageColor(stage, palette),
                  onTap: () =>
                      setState(() => _stage = _stage == stage ? null : stage),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (missingHistory > 0) ...[
          InfoBanner(
            title: 'Stage history unavailable for $missingHistory open deals',
            message:
                'Their current-stage age falls back to deal creation date and is labelled accordingly on the deal detail.',
            color: palette.amber,
            icon: Icons.history_toggle_off_rounded,
          ),
          const SizedBox(height: 14),
        ],
        SectionHeader(
          title: _stage == null ? 'Open deals' : '${_stage!.label} deals',
          subtitle:
              '${filtered.length} deals · sorted by value · tap for the full journey',
          action: PulsePill(
            label: formatMoneyMinor(
              filtered.fold<int>(0, (sum, deal) => sum + deal.valueMinor),
              compact: true,
            ),
            dense: true,
            filled: true,
            color: palette.accent,
          ),
        ),
        if (filtered.isEmpty)
          const EmptyState(
            title: 'No open deals in this stage',
            message: 'Try another stage or widen the filter context.',
            icon: Icons.view_kanban_outlined,
          )
        else
          for (final deal in filtered)
            EntranceFade(
              key: ValueKey((_stage, deal.id)),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _DealCard(deal: deal, bundle: bundle),
              ),
            ),
        const SizedBox(height: 10),
        SectionHeader(
          title: 'Stage ageing',
          subtitle: 'Median days in stage across all open deals',
        ),
        _StageAgeingCard(bundle: bundle),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Closed in period',
          subtitle: 'Won and lost outcomes are excluded from open pipeline',
        ),
        _ClosedOutcomesCard(bundle: bundle),
        const SizedBox(height: 16),
        CoverageNote(
          text:
              'Open pipeline is a snapshot, not a forecast or weighted pipeline. Stage ageing uses recorded stage history and the fixed as-of date.',
        ),
      ],
    );
  }

  bool _isStalled(AnalyticsBundle bundle, Deal deal) {
    final activityAge = bundle.scope.lastActivityAgeDays(deal);
    return bundle.scope.stageAgeDays(deal) > 14 ||
        (activityAge != null && activityAge > 14);
  }
}

abstract final class SalesDatasetStages {
  static const pipeline = [
    DealStage.newStage,
    DealStage.qualified,
    DealStage.discovery,
    DealStage.proposal,
    DealStage.negotiation,
  ];
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.label,
    required this.count,
    required this.valueMinor,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final int valueMinor;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? color.withValues(alpha: 0.12) : palette.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 132,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? color.withValues(alpha: 0.42)
                    : palette.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: palette.textSecondary,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '$count',
                  style: AppTypography.numeric(
                    theme.textTheme.headlineSmall!,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  count == 0
                      ? 'No deals'
                      : formatMoneyMinor(valueMinor, compact: true),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                    fontSize: 9.5,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  const _DealCard({required this.deal, required this.bundle});

  final Deal deal;
  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final theme = Theme.of(context);
    final account = bundle.dataset.accountsById[deal.accountId];
    final owner = bundle.dataset.usersById[deal.ownerId];
    final stageAge = bundle.scope.stageAgeDays(deal);
    final lastActivity = deal.lastActivityAt;
    final stalled =
        stageAge > 14 ||
        (lastActivity != null && bundle.scope.lastActivityAgeDays(deal)! > 14);
    final stageColor = dealStageColor(deal.stage, palette);

    return AppCard(
      onTap: () => context.push('/deals/${deal.id}'),
      padding: const EdgeInsets.all(15),
      borderColor: stalled
          ? palette.amber.withValues(alpha: 0.35)
          : palette.border,
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
              PulsePill(
                label: deal.stage.label,
                color: stageColor,
                filled: true,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            deal.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: UnitTag(productId: deal.productId),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PulseHero(
                      tag: dealHeroTag(deal.id),
                      child: Text(
                        formatMoneyMinor(deal.valueMinor),
                        style: AppTypography.numeric(
                          theme.textTheme.headlineSmall!,
                          size: 20,
                        ),
                      ),
                    ),
                    PulsePill(
                      label: deal.probability == null
                          ? 'Probability unavailable'
                          : '${(deal.probability! * 100).round()}% probability',
                      dense: true,
                      color: palette.textMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (owner != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UserAvatar(userId: owner.id, size: 22),
                    const SizedBox(width: 5),
                    Text(
                      owner.displayName.split(' ').first,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.textSecondary,
                        fontSize: 9.5,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 10,
            runSpacing: 5,
            children: [
              _DealMeta(
                icon: Icons.timer_outlined,
                label: '${formatDurationDays(stageAge)} in stage',
                color: stageAge > 14 ? palette.amber : palette.textMuted,
              ),
              _DealMeta(
                icon: Icons.bolt_outlined,
                label: lastActivity == null
                    ? 'No activity recorded'
                    : 'Last ${formatRelativeDate(lastActivity, bundle.dataset.manifest.asOf)}',
                color: palette.textMuted,
              ),
              if (stalled)
                _DealMeta(
                  icon: Icons.flag_outlined,
                  label: 'Review flag',
                  color: palette.amber,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DealMeta extends StatelessWidget {
  const _DealMeta({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontSize: 9.5,
            letterSpacing: 0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StageAgeingCard extends StatelessWidget {
  const _StageAgeingCard({required this.bundle});

  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    final stages = bundle.pipelineStages;
    final maxAge = stages.isEmpty
        ? 1.0
        : stages
              .map((stage) => stage.medianDaysInStage ?? 0)
              .reduce((a, b) => a > b ? a : b);
    return AppCard(
      child: stages.isEmpty
          ? Text('No open stage data.', style: theme.textTheme.bodySmall)
          : Column(
              children: [
                for (final stage in stages) ...[
                  Row(
                    children: [
                      SizedBox(
                        width: 78,
                        child: Text(
                          stage.stage.label,
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
                          value: maxAge == 0
                              ? 0
                              : (stage.medianDaysInStage ?? 0) / maxAge,
                          color: dealStageColor(stage.stage, palette),
                          height: 6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 48,
                        child: Text(
                          stage.medianDaysInStage == null
                              ? '—'
                              : formatDurationDays(stage.medianDaysInStage!),
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
                  if (stage != stages.last) const SizedBox(height: 9),
                ],
              ],
            ),
    );
  }
}

class _ClosedOutcomesCard extends StatelessWidget {
  const _ClosedOutcomesCard({required this.bundle});

  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final won = bundle.sales.wonDeals;
    final lost = bundle.sales.lostDeals;
    final total = won + lost;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: _OutcomeTile(
              label: 'Won',
              count: won,
              color: palette.positive,
              value: formatMoneyMinor(
                bundle.sales.bookedSalesMinor,
                compact: true,
              ),
            ),
          ),
          Container(width: 1, height: 48, color: palette.border),
          Expanded(
            child: _OutcomeTile(
              label: 'Lost',
              count: lost,
              color: palette.negative,
              value: total == 0
                  ? '—'
                  : '${(lost / total * 100).round()}% of closed',
            ),
          ),
          Container(width: 1, height: 48, color: palette.border),
          Expanded(
            child: _OutcomeTile(
              label: 'Win rate',
              count: null,
              color: palette.sky,
              value: bundle.sales.winRate == null
                  ? '—'
                  : formatPercent(bundle.sales.winRate!),
              countLabel: 'closed-deal basis',
            ),
          ),
        ],
      ),
    );
  }
}

class _OutcomeTile extends StatelessWidget {
  const _OutcomeTile({
    required this.label,
    required this.count,
    required this.color,
    required this.value,
    this.countLabel,
  });

  final String label;
  final int? count;
  final Color color;
  final String value;
  final String? countLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontSize: 8.5,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 5),
        if (count != null)
          Text(
            '$count',
            style: AppTypography.numeric(
              theme.textTheme.headlineSmall!,
              size: 21,
            ),
          )
        else
          Text(
            value,
            style: AppTypography.numeric(
              theme.textTheme.headlineSmall!,
              size: 21,
            ),
          ),
        const SizedBox(height: 1),
        Text(
          count == null ? (countLabel ?? '') : value,
          style: theme.textTheme.labelSmall?.copyWith(
            color: palette.textMuted,
            fontSize: 9,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
