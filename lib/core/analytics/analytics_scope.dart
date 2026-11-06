import '../models/deal.dart';
import '../models/enums.dart';
import '../models/lead.dart';
import '../models/sales_activity.dart';
import '../models/sales_dataset.dart';
import '../models/sales_user.dart';
import 'reporting_filter.dart';

/// Applies the shared reporting filter to the immutable dataset.
///
/// The scope deliberately separates context filters (owner, unit, source,
/// stage) from the reporting window so snapshot metrics such as open pipeline
/// remain honest.
class AnalyticsScope {
  AnalyticsScope({
    required this.dataset,
    required this.filter,
    required this.window,
  });

  final SalesDataset dataset;
  final ReportingFilter filter;
  final ReportWindow window;

  DateTime get asOf => dataset.manifest.asOf;

  bool matchesUser(String ownerId) =>
      filter.ownerId == null || filter.ownerId == ownerId;

  /// True when [productId] belongs to the filtered unit (or no unit is set).
  bool matchesUnit(String productId) =>
      filter.unitId == null || dataset.unitIdOf(productId) == filter.unitId;

  bool matchesLead(Lead lead, {bool applySource = true}) {
    if (!matchesUser(lead.ownerId)) return false;
    if (!matchesUnit(lead.productId)) return false;
    if (applySource && filter.source != null && lead.source != filter.source) {
      return false;
    }
    return true;
  }

  bool matchesDeal(Deal deal, {bool applyStage = true}) {
    if (!matchesUser(deal.ownerId)) return false;
    if (!matchesUnit(deal.productId)) return false;
    if (applyStage && filter.stage != null && deal.stage != filter.stage) {
      return false;
    }
    if (filter.source != null) {
      final lead = deal.leadId == null ? null : dataset.leadsById[deal.leadId];
      if (lead == null || lead.source != filter.source) return false;
    }
    return true;
  }

  /// With a unit filter, an activity counts only through its linked deal (or
  /// else lead); internal time with no link is left out.
  bool matchesActivity(SalesActivity activity) {
    if (!matchesUser(activity.ownerId)) return false;
    if (filter.unitId == null) return true;
    final productId = activity.dealId != null
        ? dataset.dealsById[activity.dealId]?.productId
        : activity.leadId != null
        ? dataset.leadsById[activity.leadId]?.productId
        : null;
    return productId != null && matchesUnit(productId);
  }

  Iterable<Deal> get contextDeals =>
      dataset.deals.where((deal) => matchesDeal(deal));

  Iterable<Deal> get dealsClosedInWindow => dataset.deals.where(
    (deal) =>
        deal.outcome != DealOutcome.open &&
        deal.closedAt != null &&
        window.contains(deal.closedAt!) &&
        matchesDeal(deal, applyStage: false),
  );

  Iterable<Deal> get wonDealsInWindow =>
      dealsClosedInWindow.where((deal) => deal.outcome == DealOutcome.won);

  Iterable<Deal> get lostDealsInWindow =>
      dealsClosedInWindow.where((deal) => deal.outcome == DealOutcome.lost);

  Iterable<Deal> get openDealsSnapshot => dataset.deals.where(
    (deal) => deal.outcome == DealOutcome.open && matchesDeal(deal),
  );

  Iterable<Lead> get leadsCreatedInWindow => dataset.leads.where(
    (lead) => window.contains(lead.createdAt) && matchesLead(lead),
  );

  Iterable<SalesActivity> get activitiesInWindow => dataset.activities.where(
    (activity) =>
        window.contains(activity.startedAt) && matchesActivity(activity),
  );

  /// Active reps in context. With a unit filter: reps with at least one lead
  /// or deal in that unit.
  List<SalesUser> get matchingUsers {
    final unitId = filter.unitId;
    final inUnit = unitId == null
        ? null
        : {
            for (final lead in dataset.leads)
              if (dataset.unitIdOf(lead.productId) == unitId) lead.ownerId,
            for (final deal in dataset.deals)
              if (dataset.unitIdOf(deal.productId) == unitId) deal.ownerId,
          };
    return dataset.activeUsers
        .where((user) {
          if (filter.ownerId != null && user.id != filter.ownerId) return false;
          if (inUnit != null && !inUnit.contains(user.id)) return false;
          return true;
        })
        .toList(growable: false);
  }

  AnalyticsScope previous() =>
      AnalyticsScope(dataset: dataset, filter: filter, window: window.previous);

  /// Stage entry timestamp for an open deal, falling back to creation.
  DateTime stageEnteredAt(Deal deal) {
    final events = dataset.stageEventsFor(deal.id);
    if (events.isEmpty) return deal.createdAt;
    return events.last.occurredAt;
  }

  double stageAgeDays(Deal deal) {
    final entered = stageEnteredAt(deal);
    return asOf.difference(entered).inMinutes / (60 * 24);
  }

  double? lastActivityAgeDays(Deal deal) {
    final last = deal.lastActivityAt;
    if (last == null) return null;
    return asOf.difference(last).inMinutes / (60 * 24);
  }
}
