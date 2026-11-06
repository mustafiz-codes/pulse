import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/feedback/haptics.dart';
import '../../app/shell/pulse_shell.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/widgets/app_card.dart';
import '../../app/widgets/filter_bar.dart';
import '../../app/widgets/layout.dart';
import '../../app/widgets/numbers.dart';
import '../../app/widgets/section.dart';
import '../../app/widgets/unit_tag.dart';
import '../../app/widgets/user_avatar.dart';
import '../../core/analytics/reporting_filter.dart';
import '../../core/data/providers.dart';
import '../../core/utils/currency_format.dart';

/// One business unit: what it booked, which products sold, and who sold them.
class UnitDetailScreen extends ConsumerWidget {
  const UnitDetailScreen({super.key, required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataset = ref.watch(salesDatasetProvider);
    final unit = dataset.unitsById[unitId];
    if (unit == null) {
      return const PulseDetailScaffold(
        title: 'Unit',
        child: Padding(
          padding: EdgeInsets.all(18),
          child: EmptyState(
            title: 'Unit not found',
            message: 'This business unit is not in the demo dataset.',
            icon: Icons.domain_disabled_outlined,
          ),
        ),
      );
    }

    final bundle = ref.watch(analyticsBundleProvider);
    final detail = ref.watch(unitDetailProvider(unitId));
    final performance = detail.unit;
    final theme = Theme.of(context);
    final palette = context.pulse;

    return PulseDetailScaffold(
      title: unit.label,
      subtitle: bundle.window.label,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        children: [
          const AnalyticsFilterBar(),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UnitTag(unitId: unit.id),
                const SizedBox(height: 10),
                Text(
                  'Booked sales',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatMoneyMinor(performance.bookedMinor),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 8),
                DeltaChip(
                  value: performance.bookedDeltaMinor.toDouble(),
                  label:
                      '${formatMoneyMinorSigned(performance.bookedDeltaMinor, compact: true)} vs previous',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ResponsiveGrid(
            children: [
              KpiCard(
                label: 'Won deals',
                value: Text(
                  '${performance.wonCount}',
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 24,
                  ),
                ),
              ),
              KpiCard(
                label: 'Open pipeline',
                value: Text(
                  formatMoneyMinor(
                    performance.openPipelineMinor,
                    compact: true,
                  ),
                  style: AppTypography.numeric(
                    theme.textTheme.displaySmall!,
                    size: 24,
                  ),
                ),
                footnote: '${performance.openCount} open deals',
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionHeader(
            title: 'Top products',
            subtitle: 'Booked value in the period',
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                for (var i = 0; i < detail.products.length; i++)
                  _Row(
                    divider: i < detail.products.length - 1,
                    leading: null,
                    title: detail.products[i].label,
                    subtitle:
                        '${detail.products[i].wonCount} won · ${detail.products[i].openCount} open',
                    value: formatMoneyMinor(detail.products[i].bookedMinor),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Sold by'),
          if (detail.reps.isEmpty)
            const EmptyState(
              title: 'No sales in this period',
              message: 'Nobody won or opened a deal in this unit.',
            )
          else
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  for (var i = 0; i < detail.reps.length; i++)
                    _Row(
                      divider: i < detail.reps.length - 1,
                      leading: UserAvatar(userId: detail.reps[i].userId),
                      title:
                          dataset
                              .usersById[detail.reps[i].userId]
                              ?.displayName ??
                          detail.reps[i].userId,
                      subtitle:
                          '${detail.reps[i].wonCount} won · ${detail.reps[i].openCount} open',
                      value: formatMoneyMinor(detail.reps[i].bookedMinor),
                      onTap: () =>
                          context.push('/team/${detail.reps[i].userId}'),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () {
              PulseHaptics.confirm();
              ref.read(reportingFilterProvider.notifier).setUnit(unit.id);
              context.go('/pipeline');
            },
            icon: const Icon(Icons.view_kanban_outlined),
            label: Text('View ${unit.label} pipeline'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.divider,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onTap,
  });

  final bool divider;
  final Widget? leading;
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          border: divider
              ? Border(bottom: BorderSide(color: palette.border))
              : null,
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              value,
              style: AppTypography.numeric(
                theme.textTheme.titleSmall!,
                weight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
