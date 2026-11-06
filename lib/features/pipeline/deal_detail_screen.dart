import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell/pulse_shell.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/semantic_colors.dart';
import '../../app/widgets/app_card.dart';
import '../../app/widgets/hero_tags.dart';
import '../../app/widgets/layout.dart';
import '../../app/widgets/people.dart';
import '../../app/widgets/section.dart';
import '../../app/widgets/timeline.dart';
import '../../app/widgets/unit_tag.dart';
import '../../app/widgets/user_avatar.dart';
import '../../core/data/providers.dart';
import '../../core/models/deal.dart';
import '../../core/models/enums.dart';
import '../../core/models/lead.dart';
import '../../core/models/sales_dataset.dart';
import '../../core/utils/currency_format.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/labels.dart';

class DealDetailScreen extends ConsumerWidget {
  const DealDetailScreen({super.key, required this.dealId});

  final String dealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataset = ref.watch(salesDatasetProvider);
    final deal = dataset.dealsById[dealId];
    if (deal == null) {
      return PulseDetailScaffold(
        title: 'Deal not found',
        child: Center(
          child: Text(
            'No deal exists with id $dealId.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    final account = dataset.accountsById[deal.accountId];
    final owner = dataset.usersById[deal.ownerId];
    final lead = deal.leadId == null ? null : dataset.leadsById[deal.leadId];
    final events = dataset.stageEventsFor(deal.id);
    final activities = dataset.activitiesForDeal(deal.id);
    final theme = Theme.of(context);
    final palette = context.pulse;
    final asOf = dataset.manifest.asOf;
    final end = deal.closedAt ?? asOf;
    final stageColor = dealStageColor(deal.stage, palette);
    final currentStageAge =
        asOf
            .difference(
              events.isEmpty ? deal.createdAt : events.last.occurredAt,
            )
            .inMinutes /
        60 /
        24;
    final lastActivityAge = deal.lastActivityAt == null
        ? null
        : asOf.difference(deal.lastActivityAt!).inMinutes / 60 / 24;
    final ageDays = end.difference(deal.createdAt).inDays;
    final leadToWin = lead == null || deal.closedAt == null
        ? null
        : deal.closedAt!.difference(lead.createdAt).inDays;

    return PulseDetailScaffold(
      title: account?.name ?? 'Deal',
      subtitle:
          '${deal.stage.label} · ${formatMoneyMinor(deal.valueMinor, compact: true)}',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          AppCard(
            padding: const EdgeInsets.all(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                stageColor.withValues(alpha: palette.isDark ? 0.13 : 0.07),
                palette.surface,
              ],
            ),
            borderColor: stageColor.withValues(alpha: 0.26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PulsePill(
                      label: deal.stage.label,
                      color: stageColor,
                      filled: true,
                    ),
                    PulsePill(
                      label: deal.outcome.label,
                      color: outcomeColor(deal.outcome, palette),
                      dense: true,
                    ),
                    if (lead != null)
                      PulsePill(
                        label: '${lead.source.label} lead',
                        icon: leadSourceIcon(lead.source),
                        color: palette.sky,
                        dense: true,
                      ),
                    Text(
                      deal.id,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.textMuted,
                        fontSize: 9,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Text(
                  account?.name ?? 'Unknown account',
                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 3),
                Text(deal.title, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                UnitTag(productId: deal.productId),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 9,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    PulseHero(
                      tag: dealHeroTag(deal.id),
                      child: Text(
                        formatMoneyMinor(deal.valueMinor),
                        style: AppTypography.numeric(
                          theme.textTheme.displaySmall!,
                          size: 30,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: PulsePill(
                        label: deal.probability == null
                            ? 'Probability unavailable'
                            : '${(deal.probability! * 100).round()}% probability',
                        dense: true,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(color: palette.border),
                const SizedBox(height: 10),
                _DetailRow(
                  label: 'Owner',
                  value: owner?.displayName ?? deal.ownerId,
                  trailing: owner == null
                      ? null
                      : UserAvatar(userId: owner.id, size: 24),
                ),
                _DetailRow(
                  label: 'Created',
                  value: formatDateTime(deal.createdAt),
                ),
                _DetailRow(
                  label: 'Closed',
                  value: deal.closedAt == null
                      ? 'Still open at as-of date'
                      : formatDateTime(deal.closedAt!),
                  tone: deal.closedAt == null ? null : stageColor,
                ),
                _DetailRow(
                  label: 'Last activity',
                  value: deal.lastActivityAt == null
                      ? 'No activity recorded'
                      : formatDateTime(deal.lastActivityAt!),
                  tone: deal.lastActivityAt == null ? palette.amber : null,
                ),
                _DetailRow(
                  label: 'Original source',
                  value: lead == null ? 'No linked lead' : lead.source.label,
                  tone: lead == null ? palette.textMuted : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ResponsiveGrid(
            minItemWidth: 140,
            children: [
              KpiCard(
                label: 'Deal age',
                value: Text(
                  formatDayCount(ageDays),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 24,
                  ),
                ),
                footnote: deal.closedAt == null
                    ? 'to fixed as-of date'
                    : 'creation to close',
              ),
              KpiCard(
                label: 'Current stage age',
                value: Text(
                  formatDurationDays(currentStageAge),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 24,
                    color: currentStageAge > 14 ? palette.amber : null,
                  ),
                ),
                footnote: events.isEmpty
                    ? 'history unavailable · from creation'
                    : 'since last stage change',
              ),
              KpiCard(
                label: 'Last meaningful activity',
                value: Text(
                  lastActivityAge == null
                      ? 'Not recorded'
                      : formatDurationDays(lastActivityAge),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: lastActivityAge == null ? 18 : 24,
                    color: lastActivityAge == null ? palette.amber : null,
                  ),
                ),
                footnote: lastActivityAge == null
                    ? 'no activity timestamp'
                    : 'elapsed to as-of date',
              ),
              KpiCard(
                label: 'Lead → close',
                value: Text(
                  leadToWin == null ? '—' : formatDayCount(leadToWin),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 24,
                  ),
                ),
                footnote: lead == null
                    ? 'no linked lead'
                    : deal.closedAt == null
                    ? 'not yet closed'
                    : 'lead creation to close',
              ),
            ],
          ),
          if (lead != null) ...[
            const SizedBox(height: 18),
            const SectionHeader(
              title: 'Lead journey',
              subtitle: 'Distinct starting points, never conflated',
            ),
            _LeadJourneyCard(lead: lead, deal: deal, dataset: dataset),
          ],
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Stage timeline',
            subtitle: events.isEmpty
                ? 'No recorded stage history'
                : '${events.length} stage changes · tap for details',
          ),
          if (events.isEmpty)
            InfoBanner(
              title: 'Stage history unavailable',
              message:
                  'This deal has no stage events in the fixture. Current-stage age is calculated from deal creation and is labelled as a fallback.',
              color: palette.amber,
              icon: Icons.history_toggle_off_rounded,
            )
          else
            AppCard(
              child: PulseTimeline(
                entries: _stageEntries(context, events, deal, asOf),
              ),
            ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Recorded activity',
            subtitle: '${activities.length} linked activities',
          ),
          AppCard(
            child: activities.isEmpty
                ? Text(
                    'No activities are linked to this deal.',
                    style: theme.textTheme.bodySmall,
                  )
                : PulseTimeline(
                    entries: _activityEntries(context, activities, dataset),
                  ),
          ),
          const SizedBox(height: 18),
          if (lead != null) ...[
            const SectionHeader(title: 'Original lead'),
            AppCard(
              onTap: () => context.push('/leads/${lead.id}'),
              child: Row(
                children: [
                  InitialsAvatar(
                    name: dataset.accountsById[lead.accountId]?.name ?? 'Lead',
                    size: 36,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${lead.source.label} lead · ${lead.status.label}',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Created ${formatDate(lead.createdAt)} · '
                          'first contact ${lead.firstContactedAt == null ? 'not recorded' : formatDate(lead.firstContactedAt!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: palette.textMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (owner != null) ...[
            const SectionHeader(title: 'Owner'),
            AppCard(
              onTap: () => context.push('/team/${owner.id}'),
              child: Row(
                children: [
                  InitialsAvatar(name: owner.displayName, size: 38),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          owner.displayName,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          '${jobRoleLabel(owner.jobRole)} · ${unitLabel(owner.homeUnitId)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: palette.textMuted,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          CoverageNote(
            text:
                'Stage durations use recorded stage-change events and the fixed as-of date. Missing history is disclosed and never back-filled with invented transitions.',
          ),
        ],
      ),
    );
  }

  List<TimelineEntry> _stageEntries(
    BuildContext context,
    List<dynamic> events,
    Deal deal,
    DateTime asOf,
  ) {
    final palette = context.pulse;
    return [
      for (var i = 0; i < events.length; i++)
        () {
          final event = events[i];
          final end = i + 1 < events.length
              ? events[i + 1].occurredAt as DateTime
              : (deal.closedAt ?? asOf);
          final dwell = end.difference(event.occurredAt as DateTime);
          final days = dwell.inMinutes / 60 / 24;
          final stage = event.toStage as DealStage;
          return TimelineEntry(
            title: stage.isTerminal
                ? (stage == DealStage.won ? 'Deal won' : 'Deal lost')
                : 'Moved to ${stage.label}',
            subtitle: event.fromStage == null
                ? 'Deal entered the pipeline'
                : 'From ${(event.fromStage as DealStage).label}',
            meta:
                '${formatDateTime(event.occurredAt as DateTime)} · ${formatDurationDays(days)} in stage',
            timeLabel: i == events.length - 1 && deal.closedAt == null
                ? 'Current'
                : null,
            icon: stage.isTerminal
                ? (stage == DealStage.won
                      ? Icons.emoji_events_rounded
                      : Icons.cancel_outlined)
                : Icons.arrow_forward_rounded,
            color: dealStageColor(stage, palette),
            onTap: () => _showStageSheet(
              context,
              stage: stage,
              from: event.fromStage as DealStage?,
              enteredAt: event.occurredAt as DateTime,
              leftAt: end,
              days: days,
              source: event.source as String,
            ),
          );
        }(),
    ];
  }

  List<TimelineEntry> _activityEntries(
    BuildContext context,
    List<dynamic> activities,
    SalesDataset dataset,
  ) {
    final sorted = [...activities]
      ..sort(
        (a, b) => (b.startedAt as DateTime).compareTo(a.startedAt as DateTime),
      );
    return [
      for (final activity in sorted)
        TimelineEntry(
          title:
              (activity.summary as String?) ??
              (activity.type as ActivityType).label,
          subtitle:
              '${(activity.type as ActivityType).label} · ${(activity.workCategory as WorkCategory).label}',
          meta:
              '${activity.durationMinutes == null ? 'Duration not recorded' : formatMinutes(activity.durationMinutes as int)} · '
              '${(activity.timeQuality as TimeQuality).label} · '
              '${dataset.usersById[activity.ownerId]?.displayName ?? activity.ownerId}',
          timeLabel: formatDateTime(activity.startedAt as DateTime),
          icon: activityIcon(activity.type as ActivityType),
          color: workCategoryColor(
            activity.workCategory as WorkCategory,
            context.pulse,
          ),
        ),
    ];
  }

  Future<void> _showStageSheet(
    BuildContext context, {
    required DealStage stage,
    required DealStage? from,
    required DateTime enteredAt,
    required DateTime leftAt,
    required double days,
    required String source,
  }) {
    final palette = context.pulse;
    return showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PulsePill(
                    label: stage.label,
                    color: dealStageColor(stage, palette),
                    filled: true,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                from == null ? 'Pipeline entry' : 'From ${from.label}',
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _DetailRow(label: 'Entered', value: formatDateTime(enteredAt)),
              _DetailRow(label: 'Left', value: formatDateTime(leftAt)),
              _DetailRow(label: 'Duration', value: formatDurationDays(days)),
              _DetailRow(label: 'Source', value: source),
              const SizedBox(height: 14),
              CoverageNote(
                text:
                    'Dwell is measured from stage entry to the next stage change, or to the fixed as-of date for the current stage.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadJourneyCard extends StatelessWidget {
  const _LeadJourneyCard({
    required this.lead,
    required this.deal,
    required this.dataset,
  });

  final Lead lead;
  final Deal deal;
  final SalesDataset dataset;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final asOf = dataset.manifest.asOf;
    final firstContact = lead.firstContactedAt;
    final close = deal.closedAt;
    final end = close ?? asOf;

    String duration(DateTime from, DateTime to) =>
        formatDurationDays(to.difference(from).inMinutes / 60 / 24);

    return AppCard(
      child: Column(
        children: [
          _JourneyRow(
            label: 'Lead created',
            date: formatDate(lead.createdAt),
            detail: '${lead.source.label} · ${lead.status.label}',
            color: palette.sky,
            icon: Icons.person_add_alt_1_rounded,
            isLast: false,
          ),
          _JourneyRow(
            label: 'First contact',
            date: firstContact == null
                ? 'Not recorded'
                : formatDate(firstContact),
            detail: firstContact == null
                ? 'Timestamp missing · not assumed zero'
                : '${duration(lead.createdAt, firstContact)} after lead creation',
            color: firstContact == null ? palette.amber : palette.teal,
            icon: Icons.bolt_rounded,
            isLast: false,
          ),
          _JourneyRow(
            label: 'Opportunity created',
            date: formatDate(deal.createdAt),
            detail:
                '${duration(firstContact ?? lead.createdAt, deal.createdAt)} after ${firstContact == null ? 'lead creation' : 'first contact'}',
            color: palette.violet,
            icon: Icons.work_outline_rounded,
            isLast: false,
          ),
          _JourneyRow(
            label: close == null
                ? 'Open at as-of date'
                : deal.outcome == DealOutcome.won
                ? 'Won'
                : 'Lost',
            date: close == null ? formatDate(asOf) : formatDate(close),
            detail:
                '${duration(deal.createdAt, end)} deal cycle · ${duration(lead.createdAt, end)} lead-to-close',
            color: close == null
                ? palette.textMuted
                : deal.outcome == DealOutcome.won
                ? palette.positive
                : palette.negative,
            icon: close == null
                ? Icons.timelapse_rounded
                : deal.outcome == DealOutcome.won
                ? Icons.emoji_events_rounded
                : Icons.cancel_outlined,
            isLast: true,
          ),
          const SizedBox(height: 4),
          CoverageNote(
            text:
                'Lead-to-close starts at lead creation; deal cycle starts at opportunity creation. The two durations are not interchangeable.',
          ),
        ],
      ),
    );
  }
}

class _JourneyRow extends StatelessWidget {
  const _JourneyRow({
    required this.label,
    required this.date,
    required this.detail,
    required this.color,
    required this.icon,
    required this.isLast,
  });

  final String label;
  final String date;
  final String detail;
  final Color color;
  final IconData icon;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Icon(icon, size: 12, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: palette.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(label, style: theme.textTheme.titleSmall),
                      ),
                      Text(
                        date,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: palette.textMuted,
                          fontSize: 9.5,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                      fontSize: 10.5,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.tone,
    this.trailing,
  });

  final String label;
  final String value;
  final Color? tone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tone ?? palette.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 6), trailing!],
        ],
      ),
    );
  }
}
