import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/reporting_filter.dart';
import '../../core/data/providers.dart';
import '../../core/models/enums.dart';
import '../../core/utils/labels.dart';
import '../feedback/haptics.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/theme_mode_provider.dart';
import 'brand.dart';
import 'filter_bar.dart';
import 'metric_info.dart';

/// Compact one-row header: brand, DEMO pill, period button and "⋯" menu.
class PulseTopBar extends StatelessWidget {
  const PulseTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 6, 8, 6),
      child: Row(
        children: [
          BrandLockup(compact: true, headerLogo: true),
          SizedBox(width: 9),
          DemoDataBadge(dense: true),
          SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: PeriodButton(),
            ),
          ),
          PulseOverflowMenu(),
        ],
      ),
    );
  }
}

/// "⋯" menu: presentation scenarios, reset, and the light/dark switch.
class PulseOverflowMenu extends ConsumerWidget {
  const PulseOverflowMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final dark = themeMode == ThemeMode.dark;
    return PopupMenuButton<_MenuAction>(
      tooltip: 'More',
      icon: const Icon(Icons.more_horiz_rounded, size: 22),
      position: PopupMenuPosition.under,
      onSelected: (action) {
        switch (action) {
          case _MenuAction.scenarios:
            showPresentationSheet(context, ref);
          case _MenuAction.reset:
            PulseHaptics.confirm();
            ref.read(reportingFilterProvider.notifier).reset();
            GoRouter.of(context).go('/overview');
          case _MenuAction.theme:
            PulseHaptics.selection();
            ref.read(themeModeProvider.notifier).toggle();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _MenuAction.scenarios,
          child: ListTile(
            leading: Icon(Icons.play_circle_outline_rounded),
            title: Text('Presentation scenarios'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: _MenuAction.reset,
          child: ListTile(
            leading: Icon(Icons.restart_alt_rounded),
            title: Text('Reset demo'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.theme,
          child: ListTile(
            leading: Icon(
              dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            title: Text(dark ? 'Light theme' : 'Dark theme'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

enum _MenuAction { scenarios, reset, theme }

/// Opens the presentation scenario sheet (guided demo jumps and reset).
Future<void> showPresentationSheet(BuildContext context, WidgetRef ref) =>
    _PresentationSheet.show(context, ref);

abstract final class _PresentationSheet {
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final dataset = ref.read(salesDatasetProvider);
    final filter = ref.read(reportingFilterProvider);
    final router = GoRouter.of(context);
    final palette = context.pulse;
    final currentLocation = GoRouterState.of(context).matchedLocation;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Presentation scenarios',
                            style: Theme.of(sheetContext).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Navigation and filter context only. Figures stay derived from the fixture.',
                            style: Theme.of(sheetContext).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const DemoDataBadge(dense: true),
                  ],
                ),
                const SizedBox(height: 14),
                for (final scenario in dataset.scenarios)
                  _ScenarioTile(
                    title: scenario.label,
                    description: scenario.description,
                    selected: filter.scenarioId == scenario.id,
                    onTap: () {
                      ref
                          .read(reportingFilterProvider.notifier)
                          .applyScenario(
                            id: scenario.id,
                            preset: _presetFor(scenario.period),
                            unitId: scenario.unitId,
                            ownerId: scenario.ownerId,
                            stage: scenario.stage,
                          );
                      Navigator.of(sheetContext).pop();
                      if (scenario.route == currentLocation) return;
                      if (_tabRoutes.contains(scenario.route)) {
                        router.go(scenario.route);
                      } else {
                        router.push(scenario.route);
                      }
                    },
                  ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.restart_alt_rounded,
                    color: palette.textSecondary,
                  ),
                  title: Text(
                    'Reset demo',
                    style: Theme.of(sheetContext).textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    'Clear filters and return to the October overview.',
                    style: Theme.of(sheetContext).textTheme.bodySmall,
                  ),
                  onTap: () {
                    PulseHaptics.confirm();
                    ref.read(reportingFilterProvider.notifier).reset();
                    Navigator.of(sheetContext).pop();
                    if (currentLocation != '/overview') {
                      router.go('/overview');
                    }
                  },
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 13,
                      color: palette.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Synthetic data · No monday.com connection · No edits are saved',
                        style: Theme.of(
                          sheetContext,
                        ).textTheme.bodySmall?.copyWith(fontSize: 10.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static const _tabRoutes = {'/overview', '/leads', '/pipeline', '/team'};

  static PeriodPreset _presetFor(String? period) => switch (period) {
    'last7Days' => PeriodPreset.last7Days,
    'last30Days' => PeriodPreset.last30Days,
    'quarter' => PeriodPreset.quarter,
    _ => PeriodPreset.thisMonth,
  };
}

class _ScenarioTile extends StatelessWidget {
  const _ScenarioTile({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? palette.accentSoft : palette.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? palette.accent.withValues(alpha: 0.4)
                    : palette.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 18,
                  color: selected ? palette.accent : palette.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall,
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
        ),
      ),
    );
  }
}

class FilterSummaryStrip extends ConsumerWidget {
  const FilterSummaryStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reportingFilterProvider);
    final dataset = ref.watch(salesDatasetProvider);
    final scenario = filter.scenarioId == null
        ? null
        : dataset.scenarios
              .where((item) => item.id == filter.scenarioId)
              .firstOrNull;
    final chips = <Widget>[];
    if (scenario != null) {
      chips.add(
        PulseFilterTag(
          label: scenario.label,
          color: context.pulse.accent,
          onRemove: () => ref.read(reportingFilterProvider.notifier).reset(),
        ),
      );
    }
    if (filter.unitId != null) {
      chips.add(
        PulseFilterTag(
          label: unitLabel(filter.unitId!),
          onRemove: () =>
              ref.read(reportingFilterProvider.notifier).setUnit(null),
        ),
      );
    }
    if (filter.ownerId != null) {
      final owner = dataset.usersById[filter.ownerId];
      chips.add(
        PulseFilterTag(
          label: owner?.displayName ?? filter.ownerId!,
          onRemove: () =>
              ref.read(reportingFilterProvider.notifier).setOwner(null),
        ),
      );
    }
    if (filter.source != null) {
      chips.add(
        PulseFilterTag(
          label: filter.source!.label,
          onRemove: () =>
              ref.read(reportingFilterProvider.notifier).setSource(null),
        ),
      );
    }
    if (filter.stage != null) {
      chips.add(
        PulseFilterTag(
          label: '${filter.stage!.label} stage',
          onRemove: () =>
              ref.read(reportingFilterProvider.notifier).setStage(null),
        ),
      );
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(spacing: 6, runSpacing: 6, children: chips),
    );
  }
}

class PulseFilterTag extends StatelessWidget {
  const PulseFilterTag({
    super.key,
    required this.label,
    this.color,
    this.onRemove,
  });

  final String label;
  final Color? color;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final tone = color ?? palette.textSecondary;
    return Container(
      padding: const EdgeInsets.only(left: 9, right: 4, top: 3, bottom: 3),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: palette.isDark ? 0.13 : 0.09),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: tone.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tone,
              fontWeight: FontWeight.w600,
              fontSize: 10,
              letterSpacing: 0.1,
            ),
          ),
          if (onRemove != null)
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(99),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(Icons.close_rounded, size: 12, color: tone),
              ),
            ),
        ],
      ),
    );
  }
}

class FilterChipButton extends StatelessWidget {
  const FilterChipButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    return Material(
      color: selected ? palette.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: () {
          PulseHaptics.selection();
          onTap();
        },
        borderRadius: BorderRadius.circular(99),
        child: AnimatedContainer(
          duration: context.motion(const Duration(milliseconds: 180)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected
                  ? palette.accent.withValues(alpha: 0.45)
                  : palette.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: selected ? palette.accent : palette.textMuted,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? palette.textPrimary : palette.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SourceIcon extends StatelessWidget {
  const SourceIcon({super.key, required this.source, this.size = 15});

  final LeadSource source;
  final double size;

  @override
  Widget build(BuildContext context) {
    final icon = switch (source) {
      LeadSource.inbound => Icons.call_received_rounded,
      LeadSource.outbound => Icons.call_made_rounded,
      LeadSource.referral => Icons.people_alt_outlined,
      LeadSource.event => Icons.event_outlined,
      LeadSource.partner => Icons.handshake_outlined,
      LeadSource.website => Icons.language_rounded,
    };
    return Icon(icon, size: size, color: context.pulse.textMuted);
  }
}

class MetricInfoChip extends StatelessWidget {
  const MetricInfoChip({
    super.key,
    required this.metricKey,
    required this.label,
  });

  final String metricKey;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: () => showMetricDefinition(context, metricKey),
      avatar: Icon(
        Icons.info_outline_rounded,
        size: 13,
        color: context.pulse.textMuted,
      ),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
