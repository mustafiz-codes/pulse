import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/semantic_colors.dart';
import '../../../app/widgets/people.dart';
import '../../../app/widgets/section.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/sales_activity.dart';
import '../../../core/models/sales_dataset.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/labels.dart';

/// Read-only list of the activities behind one work category. Records with
/// no valid duration are listed as "Not recorded" and are not part of the
/// headline share; estimated durations are labelled as such.
Future<void> showCategoryActivitiesSheet(
  BuildContext context, {
  required WorkCategory category,
  required List<SalesActivity> activities,
  required SalesDataset dataset,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (sheetContext, controller) => _CategoryActivitiesBody(
        category: category,
        activities: activities,
        dataset: dataset,
        controller: controller,
      ),
    ),
  );
}

class _CategoryActivitiesBody extends StatelessWidget {
  const _CategoryActivitiesBody({
    required this.category,
    required this.activities,
    required this.dataset,
    required this.controller,
  });

  final WorkCategory category;
  final List<SalesActivity> activities;
  final SalesDataset dataset;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    final color = workCategoryColor(category, palette);

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 10, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${category.label} activities · ${activities.length}',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Share of logged activity time · Estimated and missing durations are listed but not counted',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );

    if (activities.isEmpty) {
      return ListView(
        controller: controller,
        children: [
          header,
          EmptyState(
            title: 'No ${category.label.toLowerCase()} activities logged',
            message: 'Nothing in this category for the current filter.',
            icon: Icons.hourglass_empty_rounded,
          ),
        ],
      );
    }

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: activities.length + 1,
      separatorBuilder: (_, i) => i == 0
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Divider(height: 1, color: palette.border),
            ),
      itemBuilder: (context, i) {
        if (i == 0) return header;
        final activity = activities[i - 1];
        return _ActivityRow(
          key: ValueKey('activity-row-${activity.id}'),
          activity: activity,
          ownerName:
              dataset.usersById[activity.ownerId]?.displayName ??
              activity.ownerId,
          color: color,
        );
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    super.key,
    required this.activity,
    required this.ownerName,
    required this.color,
  });

  final SalesActivity activity;
  final String ownerName;
  final Color color;

  String? get _route => activity.dealId != null
      ? '/deals/${activity.dealId}'
      : activity.leadId != null
      ? '/leads/${activity.leadId}'
      : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.pulse;
    final route = _route;
    final duration = activity.durationMinutes;
    return InkWell(
      onTap: route == null ? null : () => context.push(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        child: Row(
          children: [
            Icon(activityIcon(activity.type), size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.summary ?? activity.type.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${activity.type.label} · $ownerName · ${formatDateTime(activity.startedAt)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  duration == null ? 'Not recorded' : formatMinutes(duration),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: duration == null
                        ? palette.textMuted
                        : palette.textPrimary,
                  ),
                ),
                if (activity.timeQuality == TimeQuality.estimated) ...[
                  const SizedBox(height: 4),
                  PulsePill(
                    label: 'estimated',
                    dense: true,
                    color: palette.amber,
                  ),
                ],
              ],
            ),
            if (route != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: palette.textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
