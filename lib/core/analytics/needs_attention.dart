import '../models/enums.dart';
import '../utils/currency_format.dart';
import '../utils/date_format.dart';
import '../utils/labels.dart';
import 'analytics_scope.dart';

enum AttentionType { stalledDeal, overdueFollowUp, uncontactedLead }

class AttentionItem {
  const AttentionItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.route,
    this.valueMinor,
  });

  final AttentionType type;
  final String title;
  final String subtitle;
  final String route;
  final int? valueMinor;
}

class AttentionCalculator {
  const AttentionCalculator();

  List<AttentionItem> compute(AnalyticsScope scope, {int limit = 4}) {
    final items = <AttentionItem>[];
    final dataset = scope.dataset;

    final stalled =
        scope.openDealsSnapshot
            .where((deal) => scope.stageAgeDays(deal) > 14)
            .toList()
          ..sort((a, b) => b.valueMinor.compareTo(a.valueMinor));
    for (final deal in stalled.take(2)) {
      final account = dataset.accountsById[deal.accountId];
      final days = scope.stageAgeDays(deal).round();
      items.add(
        AttentionItem(
          type: AttentionType.stalledDeal,
          title: account?.name ?? deal.title,
          subtitle:
              '${formatMoneyMinor(deal.valueMinor, compact: true)} · '
              '${deal.stage.label} · $days days in stage',
          route: '/deals/${deal.id}',
          valueMinor: deal.valueMinor,
        ),
      );
    }

    final overdue =
        scope.leadsCreatedInWindow
            .where(
              (lead) =>
                  lead.nextFollowUpAt != null &&
                  lead.nextFollowUpAt!.isBefore(scope.asOf) &&
                  lead.status != LeadStatus.converted &&
                  lead.status != LeadStatus.lost,
            )
            .toList()
          ..sort((a, b) => a.nextFollowUpAt!.compareTo(b.nextFollowUpAt!));
    for (final lead in overdue.take(1)) {
      final account = dataset.accountsById[lead.accountId];
      items.add(
        AttentionItem(
          type: AttentionType.overdueFollowUp,
          title: account?.name ?? 'Lead follow-up',
          subtitle:
              'Follow-up was due ${formatRelativeDate(lead.nextFollowUpAt!, scope.asOf)} · '
              '${lead.source.label}',
          route: '/leads/${lead.id}',
        ),
      );
    }

    final uncontacted =
        scope.leadsCreatedInWindow
            .where(
              (lead) =>
                  lead.firstContactedAt == null &&
                  lead.status == LeadStatus.newLead &&
                  scope.asOf.difference(lead.createdAt).inDays >= 2,
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final lead in uncontacted.take(1)) {
      final account = dataset.accountsById[lead.accountId];
      items.add(
        AttentionItem(
          type: AttentionType.uncontactedLead,
          title: account?.name ?? 'Uncontacted lead',
          subtitle:
              'Created ${formatRelativeDate(lead.createdAt, scope.asOf)} · '
              'no first contact recorded',
          route: '/leads/${lead.id}',
        ),
      );
    }

    return items.take(limit).toList(growable: false);
  }
}
