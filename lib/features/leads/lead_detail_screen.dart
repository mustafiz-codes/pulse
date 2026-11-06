import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell/pulse_shell.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/semantic_colors.dart';
import '../../app/widgets/app_card.dart';
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

class LeadDetailScreen extends ConsumerWidget {
  const LeadDetailScreen({super.key, required this.leadId});

  final String leadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataset = ref.watch(salesDatasetProvider);
    final lead = dataset.leadsById[leadId];
    if (lead == null) {
      return PulseDetailScaffold(
        title: 'Lead not found',
        child: Center(
          child: Text(
            'No lead exists with id $leadId.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    final account = dataset.accountsById[lead.accountId];
    final owner = dataset.usersById[lead.ownerId];
    final deal = lead.convertedDealId == null
        ? null
        : dataset.dealsById[lead.convertedDealId];
    final theme = Theme.of(context);
    final palette = context.pulse;
    final statusColor = leadStatusColor(lead.status, palette);
    final asOf = dataset.manifest.asOf;
    final ageDays = asOf.difference(lead.createdAt).inDays;
    final firstResponse = lead.firstContactedAt?.difference(lead.createdAt);
    final daysToOpportunity = deal?.createdAt.difference(lead.createdAt).inDays;
    final entries = _buildTimeline(dataset, lead, deal);

    return PulseDetailScaffold(
      title: account?.name ?? 'Lead',
      subtitle: '${lead.source.label} · ${lead.status.label}',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          AppCard(
            padding: const EdgeInsets.all(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                statusColor.withValues(alpha: palette.isDark ? 0.12 : 0.07),
                palette.surface,
              ],
            ),
            borderColor: statusColor.withValues(alpha: 0.25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PulsePill(
                      label: lead.status.label,
                      color: statusColor,
                      filled: true,
                    ),
                    const SizedBox(width: 6),
                    PulsePill(
                      label: lead.source.label,
                      icon: leadSourceIcon(lead.source),
                      color: palette.sky,
                      filled: true,
                    ),
                    const Spacer(),
                    Text(
                      lead.id,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.textMuted,
                        fontSize: 9,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  account?.name ?? 'Unknown account',
                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 6),
                UnitTag(productId: lead.productId),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (account?.industry != null)
                      PulsePill(
                        label: account!.industry!,
                        dense: true,
                        color: palette.violet,
                      ),
                    if (account?.sizeBand != null)
                      PulsePill(
                        label: '${account!.sizeBand} employees',
                        dense: true,
                        color: palette.teal,
                      ),
                    PulsePill(
                      label: '$ageDays days old',
                      dense: true,
                      color: ageDays > 14
                          ? palette.amber
                          : palette.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: palette.border),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Owner',
                  value: owner?.displayName ?? lead.ownerId,
                  trailing: owner == null
                      ? null
                      : UserAvatar(userId: owner.id, size: 24),
                ),
                _DetailRow(
                  label: 'Created',
                  value: formatDateTime(lead.createdAt),
                ),
                _DetailRow(
                  label: 'First contact',
                  value: lead.firstContactedAt == null
                      ? 'Not recorded'
                      : formatDateTime(lead.firstContactedAt!),
                  tone: lead.firstContactedAt == null ? palette.amber : null,
                ),
                _DetailRow(
                  label: 'First response',
                  value: firstResponse == null
                      ? 'Not recorded'
                      : formatDurationHours(firstResponse.inMinutes / 60),
                  tone: firstResponse == null ? palette.amber : null,
                ),
                _DetailRow(
                  label: 'Next follow-up',
                  value: lead.nextFollowUpAt == null
                      ? 'None scheduled'
                      : '${formatDate(lead.nextFollowUpAt!)} · '
                            '${formatRelativeDate(lead.nextFollowUpAt!, asOf)}',
                  tone:
                      lead.nextFollowUpAt != null &&
                          lead.nextFollowUpAt!.isBefore(asOf) &&
                          lead.status != LeadStatus.converted &&
                          lead.status != LeadStatus.lost
                      ? palette.coral
                      : null,
                ),
                if (lead.lostReason != null)
                  _DetailRow(
                    label: 'Lost reason',
                    value: lead.lostReason!,
                    tone: palette.coral,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ResponsiveGrid(
            minItemWidth: 140,
            children: [
              KpiCard(
                label: 'Lead age',
                value: Text(
                  formatDayCount(ageDays),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 25,
                  ),
                ),
                footnote: 'to fixed as-of date',
              ),
              KpiCard(
                label: 'First response',
                value: Text(
                  firstResponse == null
                      ? 'Not recorded'
                      : formatDurationHours(firstResponse.inMinutes / 60),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: firstResponse == null ? 18 : 25,
                    color: firstResponse == null ? palette.amber : null,
                  ),
                ),
                footnote: firstResponse == null
                    ? 'timestamp missing'
                    : 'lead → first contact',
              ),
              KpiCard(
                label: 'Lead → opportunity',
                value: Text(
                  daysToOpportunity == null
                      ? 'No deal'
                      : formatDayCount(daysToOpportunity),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: daysToOpportunity == null ? 18 : 25,
                  ),
                ),
                footnote: deal == null ? 'not converted' : 'to deal creation',
              ),
              KpiCard(
                label: 'Linked deal',
                value: Text(
                  deal == null
                      ? '—'
                      : formatMoneyMinor(deal.valueMinor, compact: true),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 25,
                  ),
                ),
                footnote: deal == null ? 'none' : deal.stage.label,
                onTap: deal == null
                    ? null
                    : () => context.push('/deals/${deal.id}'),
              ),
            ],
          ),
          if (lead.firstContactedAt == null) ...[
            const SizedBox(height: 14),
            InfoBanner(
              title: 'First contact not recorded',
              message:
                  'No timestamp exists for this lead. PULSE does not substitute the creation date or assume zero response time.',
              color: palette.amber,
              icon: Icons.schedule_rounded,
            ),
          ],
          const SizedBox(height: 18),
          if (deal != null) ...[
            const SectionHeader(title: 'Linked opportunity'),
            AppCard(
              onTap: () => context.push('/deals/${deal.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          deal.title,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: palette.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      PulsePill(
                        label: deal.stage.label,
                        color: dealStageColor(deal.stage, palette),
                        filled: true,
                        dense: true,
                      ),
                      const SizedBox(width: 6),
                      PulsePill(
                        label: deal.outcome.label,
                        color: outcomeColor(deal.outcome, palette),
                        dense: true,
                      ),
                      const Spacer(),
                      Text(
                        formatMoneyMinor(deal.valueMinor),
                        style: AppTypography.numeric(
                          theme.textTheme.titleSmall!,
                          size: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Created ${formatDate(deal.createdAt)}'
                    '${deal.closedAt == null ? '' : ' · closed ${formatDate(deal.closedAt!)}'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (owner != null) ...[
            const SectionHeader(title: 'Owner'),
            AppCard(
              onTap: () => context.push('/team/${owner.id}'),
              child: Row(
                children: [
                  UserAvatar(userId: owner.id, size: 40),
                  const SizedBox(width: 11),
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
            const SizedBox(height: 18),
          ],
          const SectionHeader(
            title: 'Recorded interactions',
            subtitle: 'Chronological, newest first',
          ),
          AppCard(
            child: entries.isEmpty
                ? Text(
                    'No recorded interactions for this lead.',
                    style: theme.textTheme.bodySmall,
                  )
                : PulseTimeline(entries: entries),
          ),
          const SizedBox(height: 14),
          CoverageNote(
            text:
                'Timeline combines the lead record, linked opportunity stage history and recorded activities. Missing events are not inferred.',
          ),
        ],
      ),
    );
  }

  List<TimelineEntry> _buildTimeline(
    SalesDataset dataset,
    Lead lead,
    Deal? deal,
  ) {
    final entries = <({DateTime time, TimelineEntry entry})>[];
    entries.add((
      time: lead.createdAt,
      entry: TimelineEntry(
        title: 'Lead created',
        subtitle: 'Source: ${lead.source.label}',
        timeLabel: formatDateTime(lead.createdAt),
        icon: Icons.person_add_alt_1_rounded,
      ),
    ));
    if (lead.firstContactedAt != null) {
      entries.add((
        time: lead.firstContactedAt!,
        entry: TimelineEntry(
          title: 'First contact recorded',
          subtitle: 'Recorded first-contact timestamp',
          timeLabel: formatDateTime(lead.firstContactedAt!),
          icon: Icons.bolt_rounded,
        ),
      ));
    }
    if (deal != null) {
      entries.add((
        time: deal.createdAt,
        entry: TimelineEntry(
          title: 'Opportunity created',
          subtitle: deal.title,
          timeLabel: formatDateTime(deal.createdAt),
          icon: Icons.work_outline_rounded,
        ),
      ));
      for (final event in dataset.stageEventsFor(deal.id)) {
        entries.add((
          time: event.occurredAt,
          entry: TimelineEntry(
            title: 'Stage: ${event.toStage.label}',
            subtitle: event.fromStage == null
                ? 'Deal entered the pipeline'
                : 'From ${event.fromStage!.label}',
            timeLabel: formatDateTime(event.occurredAt),
            icon: Icons.arrow_forward_rounded,
          ),
        ));
      }
      if (deal.closedAt != null) {
        entries.add((
          time: deal.closedAt!,
          entry: TimelineEntry(
            title: deal.outcome == DealOutcome.won ? 'Deal won' : 'Deal lost',
            subtitle: deal.title,
            timeLabel: formatDateTime(deal.closedAt!),
            icon: deal.outcome == DealOutcome.won
                ? Icons.emoji_events_rounded
                : Icons.cancel_outlined,
          ),
        ));
      }
    }

    final activityIds = <String>{};
    final activities = [
      ...dataset.activitiesForLead(lead.id),
      if (deal != null) ...dataset.activitiesForDeal(deal.id),
    ];
    for (final activity in activities) {
      if (!activityIds.add(activity.id)) continue;
      final category = activity.workCategory;
      final duration = activity.durationMinutes;
      entries.add((
        time: activity.startedAt,
        entry: TimelineEntry(
          title: activity.summary ?? activity.type.label,
          subtitle: '${activity.type.label} · ${category.label}',
          meta:
              '${duration == null ? 'Duration not recorded' : formatMinutes(duration)} · ${activity.timeQuality.label}',
          timeLabel: formatDateTime(activity.startedAt),
          icon: activityIcon(activity.type),
        ),
      ));
    }

    entries.sort((a, b) => b.time.compareTo(a.time));
    return entries.map((item) => item.entry).toList(growable: false);
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
            width: 96,
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
