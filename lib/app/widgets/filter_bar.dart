import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/reporting_filter.dart';
import '../../core/data/providers.dart';
import '../../core/models/enums.dart';
import '../../core/utils/labels.dart';
import '../../core/utils/date_format.dart';
import '../feedback/haptics.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import 'top_bar.dart';

/// Period switch plus a summary of any active filters. Every analytics
/// screen shows this under its title.
class AnalyticsFilterBar extends StatelessWidget {
  const AnalyticsFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [PeriodSegmentedControl(), FilterSummaryStrip()],
    );
  }
}

/// One-line 7D · 30D · Month · Quarter switch. A custom range (chosen from the
/// period sheet) leaves every segment unselected.
class PeriodSegmentedControl extends ConsumerWidget {
  const PeriodSegmentedControl({super.key});

  static const _segments = <(PeriodPreset, String, String)>[
    (PeriodPreset.last7Days, '7D', 'Last 7 days'),
    (PeriodPreset.last30Days, '30D', 'Last 30 days'),
    (PeriodPreset.thisMonth, 'Month', 'This month'),
    (PeriodPreset.quarter, 'Quarter', 'Quarter'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preset = ref.watch(reportingFilterProvider.select((f) => f.preset));
    final palette = context.pulse;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: palette.textPrimary.withValues(
          alpha: palette.isDark ? 0.08 : 0.06,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final (value, label, semantics) in _segments)
            Expanded(
              child: Semantics(
                label: semantics,
                selected: preset == value,
                button: true,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (preset != value) PulseHaptics.selection();
                    ref.read(reportingFilterProvider.notifier).setPreset(value);
                  },
                  child: AnimatedContainer(
                    duration: context.motion(AppMotion.fast),
                    curve: AppMotion.enter,
                    constraints: const BoxConstraints(minHeight: 40),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: preset == value ? palette.surface : null,
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: preset == value && !palette.isDark
                          ? [
                              BoxShadow(
                                color: palette.cardShadow,
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 13,
                        fontWeight: preset == value
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: preset == value
                            ? palette.textPrimary
                            : palette.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Header pill showing the current period ("Oct 2026 ▾"). Opens the period
/// and filter sheet; a dot marks active filters.
class PeriodButton extends ConsumerWidget {
  const PeriodButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reportingFilterProvider);
    final window = ref.watch(analyticsBundleProvider.select((b) => b.window));
    final palette = context.pulse;
    final theme = Theme.of(context);
    return Tooltip(
      message: 'Period and filters',
      child: Material(
        color: palette.surface,
        shape: StadiumBorder(
          side: palette.isDark
              ? BorderSide(color: palette.border)
              : BorderSide.none,
        ),
        elevation: palette.isDark ? 0 : 0.6,
        shadowColor: palette.cardShadow,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => showPeriodFilterSheet(context, ref),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (filter.hasAnyFilter) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: palette.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      shortWindowLabel(window, filter.preset),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: palette.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the date-range picker for a custom demo period.
Future<void> pickCustomRange(BuildContext context, WidgetRef ref) async {
  final dataset = ref.read(salesDatasetProvider);
  final filter = ref.read(reportingFilterProvider);
  final asOfLocal = dataset.manifest.asOf.toLocal();
  final initialStart =
      filter.customStart ?? DateTime(asOfLocal.year, asOfLocal.month, 1);
  final initialEnd = filter.customEnd ?? asOfLocal;
  final range = await showDateRangePicker(
    context: context,
    firstDate: dataset.manifest.periodStart.toLocal(),
    lastDate: asOfLocal,
    initialDateRange: DateTimeRange(
      start: initialStart.isAfter(initialEnd) ? initialEnd : initialStart,
      end: initialEnd,
    ),
    helpText: 'Custom demo range',
    saveText: 'Apply',
    currentDate: asOfLocal,
  );
  if (range == null) return;
  ref
      .read(reportingFilterProvider.notifier)
      .setCustomRange(range.start, range.end);
}

Future<void> showPeriodFilterSheet(BuildContext context, WidgetRef ref) {
  final dataset = ref.read(salesDatasetProvider);
  final palette = context.pulse;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Consumer(
        builder: (context, sheetRef, _) {
          final filter = sheetRef.watch(reportingFilterProvider);
          final notifier = sheetRef.read(reportingFilterProvider.notifier);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sections scroll; "Show results" stays pinned below them so
                  // it is reachable at large text sizes.
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Period and filters',
                                style: Theme.of(
                                  sheetContext,
                                ).textTheme.titleLarge,
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  notifier
                                    ..setUnit(null)
                                    ..setOwner(null)
                                    ..setSource(null)
                                    ..setStage(null);
                                },
                                child: const Text('Clear all'),
                              ),
                            ],
                          ),
                          Text(
                            'As of ${formatDate(dataset.manifest.asOf)} · '
                            '${dataset.manifest.timezone} · ${dataset.manifest.currency}',
                            style: Theme.of(sheetContext).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'These filters apply to every analytical screen.',
                            style: Theme.of(sheetContext).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () async {
                              Navigator.of(sheetContext).pop();
                              await pickCustomRange(context, ref);
                            },
                            icon: const Icon(
                              Icons.date_range_outlined,
                              size: 18,
                            ),
                            label: Text(
                              filter.preset == PeriodPreset.custom
                                  ? 'Custom range · ${sheetRef.watch(analyticsBundleProvider).window.label}'
                                  : 'Custom range',
                            ),
                          ),
                          const SizedBox(height: 18),
                          _SheetSection(
                            title: 'Unit',
                            children: [
                              _SheetChip(
                                label: 'All units',
                                selected: filter.unitId == null,
                                onTap: () => notifier.setUnit(null),
                              ),
                              for (final unit in dataset.businessUnits)
                                _SheetChip(
                                  label: unit.label,
                                  selected: filter.unitId == unit.id,
                                  onTap: () => notifier.setUnit(unit.id),
                                ),
                            ],
                          ),
                          _SheetSection(
                            title: 'Rep',
                            children: [
                              _SheetChip(
                                label: 'All owners',
                                selected: filter.ownerId == null,
                                onTap: () => notifier.setOwner(null),
                              ),
                              for (final user in dataset.activeUsers)
                                _SheetChip(
                                  label: user.displayName,
                                  selected: filter.ownerId == user.id,
                                  onTap: () => notifier.setOwner(user.id),
                                ),
                            ],
                          ),
                          _SheetSection(
                            title: 'Source',
                            children: [
                              _SheetChip(
                                label: 'All sources',
                                selected: filter.source == null,
                                onTap: () => notifier.setSource(null),
                              ),
                              for (final source in LeadSource.values)
                                _SheetChip(
                                  label: source.label,
                                  selected: filter.source == source,
                                  onTap: () => notifier.setSource(source),
                                ),
                            ],
                          ),
                          _SheetSection(
                            title: 'Stage',
                            children: [
                              _SheetChip(
                                label: 'All stages',
                                selected: filter.stage == null,
                                onTap: () => notifier.setStage(null),
                              ),
                              for (final stage in const [
                                DealStage.newStage,
                                DealStage.qualified,
                                DealStage.discovery,
                                DealStage.proposal,
                                DealStage.negotiation,
                              ])
                                _SheetChip(
                                  label: stage.label,
                                  selected: filter.stage == stage,
                                  onTap: () => notifier.setStage(stage),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 13,
                                color: palette.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Stage filters affect the open pipeline snapshot, not closed-deal KPIs.',
                                  style: Theme.of(sheetContext)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontSize: 10.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Show results'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _SheetSection extends StatelessWidget {
  const _SheetSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.pulse.textMuted,
              letterSpacing: 1.2,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(spacing: 6, runSpacing: 6, children: children),
        ],
      ),
    );
  }
}

class _SheetChip extends StatelessWidget {
  const _SheetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    return Material(
      color: selected ? palette.accentSoft : palette.surfaceAlt,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: () {
          PulseHaptics.selection();
          onTap();
        },
        borderRadius: BorderRadius.circular(99),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected
                  ? palette.accent.withValues(alpha: 0.42)
                  : palette.border,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? palette.textPrimary : palette.textSecondary,
              fontSize: 11.5,
            ),
          ),
        ),
      ),
    );
  }
}
