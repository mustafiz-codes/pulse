import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/feedback/haptics.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/semantic_colors.dart';
import '../../app/widgets/app_card.dart';
import '../../app/widgets/entrance_fade.dart';
import '../../app/widgets/filter_bar.dart';
import '../../app/widgets/layout.dart';
import '../../app/widgets/numbers.dart';
import '../../app/widgets/people.dart';
import '../../app/widgets/section.dart';
import '../../app/widgets/unit_tag.dart';
import '../../app/widgets/top_bar.dart';
import '../../core/analytics/analytics_bundle.dart';
import '../../core/data/providers.dart';
import '../../core/models/enums.dart';
import '../../core/models/lead.dart';
import '../../core/utils/currency_format.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/labels.dart';
import 'widgets/lead_preview_sheet.dart';

class LeadsScreen extends ConsumerStatefulWidget {
  const LeadsScreen({super.key});

  @override
  ConsumerState<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends ConsumerState<LeadsScreen> {
  final _searchController = TextEditingController();
  LeadStatus? _status;
  int _visible = 20;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bundle = ref.watch(analyticsBundleProvider);
    final theme = Theme.of(context);
    final palette = context.pulse;
    final leads = bundle.scope.leadsCreatedInWindow.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final notContacted =
        leads
            .where(
              (lead) =>
                  lead.firstContactedAt == null &&
                  lead.status != LeadStatus.lost &&
                  lead.status != LeadStatus.unqualified,
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final filtered = leads
        .where((lead) {
          if (_status != null && lead.status != _status) return false;
          final term = _searchController.text.trim().toLowerCase();
          if (term.isEmpty) return true;
          final account = bundle.dataset.accountsById[lead.accountId];
          final owner = bundle.dataset.usersById[lead.ownerId];
          return (account?.name.toLowerCase().contains(term) ?? false) ||
              (owner?.displayName.toLowerCase().contains(term) ?? false) ||
              lead.id.toLowerCase().contains(term) ||
              lead.source.name.contains(term) ||
              lead.status.name.contains(term);
        })
        .toList(growable: false);

    final cohort = bundle.conversion.selectedCohort;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 30),
      children: [
        const PageTitle(title: 'Lead intelligence'),
        const SizedBox(height: 14),
        const AnalyticsFilterBar(),
        const SizedBox(height: 16),
        ResponsiveGrid(
          children: [
            KpiCard(
              label: 'Leads created',
              value: AnimatedNumber(
                value: leads.length.toDouble(),
                format: (value) => value.round().toString(),
                style: AppTypography.numeric(
                  theme.textTheme.displaySmall!,
                  size: 28,
                ),
              ),
              footnote: 'in ${bundle.window.label}',
              icon: Icons.person_add_alt_1_outlined,
            ),
            KpiCard(
              label: 'Not yet contacted',
              value: AnimatedNumber(
                value: notContacted.length.toDouble(),
                format: (value) => value.round().toString(),
                style: AppTypography.numeric(
                  theme.textTheme.displaySmall!,
                  size: 28,
                  color: notContacted.isEmpty ? null : palette.amber,
                ),
              ),
              footnote: 'no first-contact timestamp',
              icon: Icons.person_off_outlined,
              accentColor: palette.amber,
            ),
            KpiCard(
              label: 'Median first response',
              metricKey: 'firstResponse',
              value: AnimatedNumber(
                value: bundle.conversion.medianFirstResponseHours ?? 0,
                format: (value) =>
                    bundle.conversion.medianFirstResponseHours == null
                    ? 'Not recorded'
                    : formatDurationHours(value),
                style: AppTypography.numeric(
                  theme.textTheme.displaySmall!,
                  size: 28,
                ),
              ),
              footnote:
                  '${bundle.conversion.firstResponseSample} of ${leads.length} leads with a timestamp',
            ),
            KpiCard(
              label: 'Lead-to-opportunity',
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
              footnote:
                  '${cohort.opportunity} of ${cohort.totalLeads} cohort leads',
            ),
          ],
        ),
        const SizedBox(height: 18),
        SectionHeader(
          title: 'Not yet contacted',
          subtitle: 'Open leads without a recorded first-contact timestamp',
          action: PulsePill(
            label: '${notContacted.length}',
            color: notContacted.isEmpty ? palette.positive : palette.amber,
            filled: true,
            dense: true,
          ),
        ),
        if (notContacted.isEmpty)
          AppCard(
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
                    'Every eligible lead in this window has a first-contact timestamp.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < notContacted.take(3).length; i++) ...[
                  _LeadRow(
                    lead: notContacted[i],
                    bundle: bundle,
                    dense: true,
                    highlight: true,
                  ),
                  if (i < notContacted.take(3).length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Divider(color: palette.border),
                    ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 20),
        const SectionHeader(
          title: 'Source performance',
          subtitle: 'Contact and conversion rates by original lead source',
        ),
        _SourcePerformanceCard(bundle: bundle),
        const SizedBox(height: 20),
        SectionHeader(
          title: 'All leads',
          subtitle: '${filtered.length} matching leads',
          action: PulsePill(
            label: '${filtered.length}',
            dense: true,
            filled: true,
            color: palette.textSecondary,
          ),
        ),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search account, owner, source or status',
            prefixIcon: const Icon(Icons.search_rounded, size: 19),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded, size: 17),
                  ),
          ),
        ),
        const SizedBox(height: 9),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChipButton(
                label: 'All',
                selected: _status == null,
                onTap: () => setState(() => _status = null),
              ),
              for (final status in LeadStatus.values) ...[
                const SizedBox(width: 6),
                FilterChipButton(
                  label: status.label,
                  selected: _status == status,
                  onTap: () => setState(() => _status = status),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          const EmptyState(
            title: 'No leads match',
            message: 'Try a different search term or status filter.',
            icon: Icons.person_search_outlined,
          )
        else ...[
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < filtered.take(_visible).length; i++) ...[
                  EntranceFade(
                    key: ValueKey((_status, filtered[i].id)),
                    child: _LeadRow(lead: filtered[i], bundle: bundle),
                  ),
                  if (i < filtered.take(_visible).length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Divider(color: palette.border),
                    ),
                ],
              ],
            ),
          ),
          if (filtered.length > _visible)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: OutlinedButton(
                onPressed: () => setState(() => _visible += 20),
                child: Text(
                  'Show 20 more · ${filtered.length - _visible} remaining',
                ),
              ),
            ),
        ],
        const SizedBox(height: 18),
        CoverageNote(
          text:
              'Lead ages use the fixed as-of date (${formatDate(bundle.dataset.manifest.asOf)}). '
              'Missing first-contact timestamps are shown as “Not recorded”, never as zero.',
        ),
      ],
    );
  }
}

class _LeadRow extends StatelessWidget {
  const _LeadRow({
    required this.lead,
    required this.bundle,
    this.dense = false,
    this.highlight = false,
  });

  final Lead lead;
  final AnalyticsBundle bundle;
  final bool dense;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;

    void preview() =>
        showLeadPreviewSheet(context, lead: lead, dataset: bundle.dataset);

    // Swiping only opens a read-only preview; the row never dismisses.
    return Dismissible(
      key: ValueKey('lead-row-${lead.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        PulseHaptics.selection();
        preview();
        return false;
      },
      background: Container(
        color: palette.surfaceAlt,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_outlined, size: 18, color: palette.textMuted),
            const SizedBox(width: 6),
            Text(
              'Preview',
              style: theme.textTheme.labelMedium?.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
      child: _rowBody(context, preview),
    );
  }

  Widget _rowBody(BuildContext context, VoidCallback preview) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    final account = bundle.dataset.accountsById[lead.accountId];
    final owner = bundle.dataset.usersById[lead.ownerId];
    final age = bundle.dataset.manifest.asOf.difference(lead.createdAt).inDays;
    final response = lead.firstContactedAt?.difference(lead.createdAt);
    final statusColor = leadStatusColor(lead.status, palette);

    return InkWell(
      onTap: () => context.push('/leads/${lead.id}'),
      onLongPress: () {
        PulseHaptics.selection();
        preview();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: dense ? 10 : 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: (highlight ? palette.amber : palette.sky).withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                leadSourceIcon(lead.source),
                size: 16,
                color: highlight ? palette.amber : palette.sky,
              ),
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
                          account?.name ?? 'Unknown account',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(width: 6),
                      PulsePill(
                        label: lead.status.label,
                        color: statusColor,
                        filled: true,
                        dense: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        leadSourceIcon(lead.source),
                        size: 11,
                        color: palette.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        lead.source.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10.5,
                        ),
                      ),
                      Text(
                        ' · ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.textMuted,
                          fontSize: 10.5,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          owner?.displayName ?? lead.ownerId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                      Text(
                        ' · $age days old',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10.5,
                          color: age > 14 ? palette.amber : palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  UnitTag(productId: lead.productId),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          response == null
                              ? Icons.remove_circle_outline_rounded
                              : Icons.bolt_rounded,
                          size: 12,
                          color: response == null
                              ? palette.amber
                              : palette.textMuted,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 3,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              response == null
                                  ? 'First response not recorded'
                                  : 'First response ${formatDurationHours(response.inMinutes / 60)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: response == null
                                    ? palette.amber
                                    : palette.textMuted,
                                fontSize: 9.5,
                                letterSpacing: 0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (lead.convertedDealId != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.link_rounded,
                                    size: 11,
                                    color: palette.positive,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Linked deal',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: palette.positive,
                                      fontSize: 9.5,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            if (lead.nextFollowUpAt != null &&
                                lead.nextFollowUpAt!.isBefore(
                                  bundle.dataset.manifest.asOf,
                                ) &&
                                lead.status != LeadStatus.converted &&
                                lead.status != LeadStatus.lost)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 11,
                                    color: palette.coral,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Follow-up overdue',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: palette.coral,
                                      fontSize: 9.5,
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
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

class _SourcePerformanceCard extends StatelessWidget {
  const _SourcePerformanceCard({required this.bundle});

  final AnalyticsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final theme = Theme.of(context);
    final sources = bundle.sources;
    if (sources.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No source activity in this window.',
          style: theme.textTheme.bodySmall,
        ),
      );
    }
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'SOURCE',
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 8.5),
                ),
              ),
              Expanded(
                child: Text(
                  'LEADS',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 8.5),
                ),
              ),
              Expanded(
                child: Text(
                  'CONTACT',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 8.5),
                ),
              ),
              Expanded(
                child: Text(
                  'WON',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 8.5),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'MEDIAN RESP.',
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 8.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final source in sources) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Icon(
                          leadSourceIcon(source.source),
                          size: 13,
                          color: palette.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            source.source.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${source.leads}',
                      textAlign: TextAlign.right,
                      style: AppTypography.numeric(
                        theme.textTheme.labelMedium!,
                        size: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      source.contactRate == null
                          ? '—'
                          : formatPercent(source.contactRate!),
                      textAlign: TextAlign.right,
                      style: AppTypography.numeric(
                        theme.textTheme.labelMedium!,
                        size: 11,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      source.conversionRate == null
                          ? '—'
                          : formatPercent(source.conversionRate!),
                      textAlign: TextAlign.right,
                      style: AppTypography.numeric(
                        theme.textTheme.labelMedium!,
                        size: 11,
                        color:
                            source.conversionRate != null &&
                                source.conversionRate! > 0
                            ? palette.positive
                            : palette.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      source.medianFirstResponseHours == null
                          ? 'Not recorded'
                          : formatDurationHours(
                              source.medianFirstResponseHours!,
                            ),
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
              ),
            ),
            Divider(color: palette.border, height: 1),
          ],
          const SizedBox(height: 8),
          CoverageNote(
            text:
                'Won shows lead-to-won conversion for the cohort. Contact rate uses recorded first-contact timestamps only.',
          ),
        ],
      ),
    );
  }
}
