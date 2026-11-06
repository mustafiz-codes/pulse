import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/semantic_colors.dart';
import '../../../app/widgets/people.dart';
import '../../../app/widgets/unit_tag.dart';
import '../../../core/models/lead.dart';
import '../../../core/models/sales_dataset.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/labels.dart';

/// Read-only quick look at a lead. There are deliberately no call, email or
/// edit affordances: PULSE never implies it can act on a contact.
Future<void> showLeadPreviewSheet(
  BuildContext context, {
  required Lead lead,
  required SalesDataset dataset,
}) {
  final router = GoRouter.of(context);
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final palette = sheetContext.pulse;
      final account = dataset.accountsById[lead.accountId];
      final owner = dataset.usersById[lead.ownerId];
      final response = lead.firstContactedAt?.difference(lead.createdAt);
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PulsePill(
                  label: lead.status.label,
                  color: leadStatusColor(lead.status, palette),
                  filled: true,
                ),
                const SizedBox(width: 6),
                PulsePill(
                  label: '${lead.source.label} lead',
                  icon: leadSourceIcon(lead.source),
                  color: palette.sky,
                  dense: true,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              account?.name ?? 'Unknown account',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            UnitTag(productId: lead.productId),
            const SizedBox(height: 14),
            _PreviewRow(label: 'Owner', value: owner?.displayName ?? '—'),
            _PreviewRow(label: 'Created', value: formatDate(lead.createdAt)),
            _PreviewRow(
              label: 'First response',
              value: response == null
                  ? 'Not recorded'
                  : formatDurationHours(response.inMinutes / 60),
            ),
            _PreviewRow(
              label: 'Next follow-up',
              value: lead.nextFollowUpAt == null
                  ? 'None scheduled'
                  : formatDate(lead.nextFollowUpAt!),
            ),
            _PreviewRow(
              label: 'Linked deal',
              value: lead.convertedDealId ?? 'None',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  router.push('/leads/${lead.id}');
                },
                child: const Text('Open lead'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}
