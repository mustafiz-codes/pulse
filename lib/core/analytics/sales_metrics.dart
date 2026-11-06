import '../models/enums.dart';
import 'analytics_scope.dart';
import 'math_utils.dart';
import 'target_metrics.dart';

class SalesMetrics {
  const SalesMetrics({
    required this.bookedSalesMinor,
    required this.wonDeals,
    required this.lostDeals,
    required this.closedDeals,
    required this.winRate,
    required this.targetMinor,
    required this.targetAttainment,
    required this.targetCoverage,
    required this.openPipelineMinor,
    required this.openDealsCount,
    required this.medianLeadToWinDays,
    required this.leadToWinSample,
    required this.leadToWinCoverage,
    required this.medianDealCycleDays,
    required this.dealCycleSample,
    required this.medianFirstResponseHours,
    required this.firstResponseSample,
    required this.uncontactedLeads,
    required this.leadsCreated,
    required this.convertedLeads,
    required this.stalledDeals,
    required this.totalDeals,
  });

  final int bookedSalesMinor;
  final int wonDeals;
  final int lostDeals;
  final int closedDeals;
  final double? winRate;
  final int? targetMinor;
  final double? targetAttainment;
  final TargetCoverage targetCoverage;
  final int openPipelineMinor;
  final int openDealsCount;
  final double? medianLeadToWinDays;
  final int leadToWinSample;
  final int leadToWinCoverage;
  final double? medianDealCycleDays;
  final int dealCycleSample;
  final double? medianFirstResponseHours;
  final int firstResponseSample;
  final int uncontactedLeads;
  final int leadsCreated;
  final int convertedLeads;
  final int stalledDeals;
  final int totalDeals;

  int get bookedSalesChangeMinor => 0; // Populated by AnalyticsBundle deltas.

  double? get leadToWinCoverageRate => safeRate(leadToWinCoverage, wonDeals);

  double? get firstResponseCoverageRate =>
      safeRate(firstResponseSample, leadsCreated);

  bool get hasClosedDeals => closedDeals > 0;
}

class SalesMetricsCalculator {
  const SalesMetricsCalculator({
    this.targetCalculator = const TargetCalculator(),
  });

  final TargetCalculator targetCalculator;

  SalesMetrics compute(AnalyticsScope scope) {
    final closed = scope.dealsClosedInWindow.toList(growable: false);
    final won = closed
        .where((deal) => deal.outcome == DealOutcome.won)
        .toList(growable: false);
    final lost = closed
        .where((deal) => deal.outcome == DealOutcome.lost)
        .toList(growable: false);

    final bookedSalesMinor = won.fold<int>(
      0,
      (total, deal) => total + deal.valueMinor,
    );

    final target = targetCalculator.forScope(scope);
    final targetMinor = target.targetMinor;
    final targetAttainment = targetMinor != null && targetMinor > 0
        ? bookedSalesMinor / targetMinor
        : null;

    final openDeals = scope.openDealsSnapshot.toList(growable: false);
    final openPipelineMinor = openDeals.fold<int>(
      0,
      (total, deal) => total + deal.valueMinor,
    );

    final leadToWinDays = <double>[];
    var leadToWinCoverage = 0;
    for (final deal in won) {
      final lead = deal.leadId == null
          ? null
          : scope.dataset.leadsById[deal.leadId];
      if (lead == null || deal.closedAt == null) continue;
      leadToWinCoverage++;
      final days =
          deal.closedAt!.difference(lead.createdAt).inMinutes / (60 * 24);
      if (days >= 0) leadToWinDays.add(days);
    }

    final dealCycleDays = <double>[
      for (final deal in won)
        if (deal.closedAt != null)
          deal.closedAt!.difference(deal.createdAt).inMinutes / (60 * 24),
    ];

    final leads = scope.leadsCreatedInWindow.toList(growable: false);
    final firstResponseHours = <double>[
      for (final lead in leads)
        if (lead.firstContactedAt != null)
          lead.firstContactedAt!.difference(lead.createdAt).inMinutes / 60,
    ];

    final stalledDeals = openDeals.where((deal) {
      final stageAge = scope.stageAgeDays(deal);
      final activityAge = scope.lastActivityAgeDays(deal);
      return stageAge > 14 || (activityAge != null && activityAge > 14);
    }).length;

    return SalesMetrics(
      bookedSalesMinor: bookedSalesMinor,
      wonDeals: won.length,
      lostDeals: lost.length,
      closedDeals: closed.length,
      winRate: safeRate(won.length, closed.length),
      targetMinor: targetMinor,
      targetAttainment: targetAttainment,
      targetCoverage: target,
      openPipelineMinor: openPipelineMinor,
      openDealsCount: openDeals.length,
      medianLeadToWinDays: median(leadToWinDays),
      leadToWinSample: leadToWinDays.length,
      leadToWinCoverage: leadToWinCoverage,
      medianDealCycleDays: median(dealCycleDays),
      dealCycleSample: dealCycleDays.length,
      medianFirstResponseHours: median(firstResponseHours),
      firstResponseSample: firstResponseHours.length,
      uncontactedLeads: leads
          .where((lead) => lead.firstContactedAt == null)
          .length,
      leadsCreated: leads.length,
      convertedLeads: leads
          .where((lead) => lead.convertedDealId != null)
          .length,
      stalledDeals: stalledDeals,
      totalDeals: scope.contextDeals.length,
    );
  }
}
