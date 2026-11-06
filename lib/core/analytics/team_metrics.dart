import '../models/enums.dart';
import '../models/sales_activity.dart';
import '../models/sales_user.dart';
import 'analytics_scope.dart';
import 'math_utils.dart';
import 'target_metrics.dart';

enum RankingMode { bookedSales, targetAttainment, winRate, cycleTime }

extension RankingModeLabel on RankingMode {
  String get label => switch (this) {
    RankingMode.bookedSales => 'Booked sales',
    RankingMode.targetAttainment => 'Target',
    RankingMode.winRate => 'Win rate',
    RankingMode.cycleTime => 'Cycle time',
  };

  String get shortLabel => switch (this) {
    RankingMode.bookedSales => 'Booked',
    RankingMode.targetAttainment => 'Target',
    RankingMode.winRate => 'Win rate',
    RankingMode.cycleTime => 'Cycle',
  };
}

class RepPerformance {
  const RepPerformance({
    required this.user,
    required this.bookedSalesMinor,
    required this.wonDeals,
    required this.lostDeals,
    required this.closedDeals,
    required this.winRate,
    required this.targetMinor,
    required this.targetAttainment,
    required this.targetCoverage,
    required this.medianCycleDays,
    required this.leadsAllocated,
    required this.openPipelineMinor,
    required this.salesMinutes,
    required this.operationsMinutes,
    required this.otherMinutes,
    required this.loggedMinutes,
    required this.coverage,
    required this.activitiesLogged,
  });

  final SalesUser user;
  final int bookedSalesMinor;
  final int wonDeals;
  final int lostDeals;
  final int closedDeals;
  final double? winRate;
  final int? targetMinor;
  final double? targetAttainment;
  final TargetCoverage targetCoverage;
  final double? medianCycleDays;
  final int leadsAllocated;
  final int openPipelineMinor;
  final int salesMinutes;
  final int operationsMinutes;
  final int otherMinutes;
  final int loggedMinutes;
  final double? coverage;
  final int activitiesLogged;

  double? get operationsShare =>
      loggedMinutes == 0 ? null : operationsMinutes / loggedMinutes;

  bool get lowSample => closedDeals < 5;
}

class TeamMetrics {
  const TeamMetrics({
    required this.reps,
    required this.totalBookedMinor,
    required this.totalTargetMinor,
    required this.attainment,
    required this.winRate,
    required this.medianCycleDays,
    required this.totalWonDeals,
    required this.totalClosedDeals,
    required this.totalOpenPipelineMinor,
    required this.headcount,
  });

  final List<RepPerformance> reps;
  final int totalBookedMinor;
  final int? totalTargetMinor;
  final double? attainment;
  final double? winRate;
  final double? medianCycleDays;
  final int totalWonDeals;
  final int totalClosedDeals;
  final int totalOpenPipelineMinor;
  final int headcount;

  List<RepPerformance> ranked(RankingMode mode) {
    final copy = [...reps];
    copy.sort((a, b) {
      switch (mode) {
        case RankingMode.bookedSales:
          return b.bookedSalesMinor.compareTo(a.bookedSalesMinor);
        case RankingMode.targetAttainment:
          final aValue = a.targetAttainment;
          final bValue = b.targetAttainment;
          if (aValue == null && bValue == null) return 0;
          if (aValue == null) return 1;
          if (bValue == null) return -1;
          return bValue.compareTo(aValue);
        case RankingMode.winRate:
          if (a.lowSample != b.lowSample) return a.lowSample ? 1 : -1;
          final aValue = a.winRate;
          final bValue = b.winRate;
          if (aValue == null && bValue == null) return 0;
          if (aValue == null) return 1;
          if (bValue == null) return -1;
          return bValue.compareTo(aValue);
        case RankingMode.cycleTime:
          if (a.lowSample != b.lowSample) return a.lowSample ? 1 : -1;
          final aValue = a.medianCycleDays;
          final bValue = b.medianCycleDays;
          if (aValue == null && bValue == null) return 0;
          if (aValue == null) return 1;
          if (bValue == null) return -1;
          return aValue.compareTo(bValue);
      }
    });
    return copy;
  }
}

class TeamMetricsCalculator {
  const TeamMetricsCalculator({
    this.targetCalculator = const TargetCalculator(),
  });

  final TargetCalculator targetCalculator;

  TeamMetrics compute(AnalyticsScope scope) {
    final reps = <RepPerformance>[];
    var totalBooked = 0;
    var totalWon = 0;
    var totalLost = 0;
    var totalTarget = 0;
    var hasTarget = false;
    final allCycleDays = <double>[];

    for (final user in scope.matchingUsers) {
      final closed = scope.dealsClosedInWindow
          .where((deal) => deal.ownerId == user.id)
          .toList(growable: false);
      final won = closed
          .where((deal) => deal.outcome == DealOutcome.won)
          .toList(growable: false);
      final lost = closed
          .where((deal) => deal.outcome == DealOutcome.lost)
          .toList(growable: false);
      final booked = won.fold<int>(0, (sum, deal) => sum + deal.valueMinor);
      final cycleDays = <double>[
        for (final deal in won)
          if (deal.closedAt != null)
            deal.closedAt!.difference(deal.createdAt).inMinutes / (60 * 24),
      ];
      final target = targetCalculator.forScope(scope, ownerIds: [user.id]);
      final targetMinor = target.targetMinor;
      if (targetMinor != null) {
        hasTarget = true;
        totalTarget += targetMinor;
      }

      final leadsAllocated = scope.leadsCreatedInWindow
          .where((lead) => lead.ownerId == user.id)
          .length;

      final openPipeline = scope.openDealsSnapshot
          .where((deal) => deal.ownerId == user.id)
          .fold<int>(0, (sum, deal) => sum + deal.valueMinor);

      final activities = scope.activitiesInWindow
          .where((activity) => activity.ownerId == user.id)
          .toList(growable: false);
      final validActivities = activities
          .where(
            (activity) =>
                activity.hasValidLoggedDuration &&
                activity.workCategory != WorkCategory.unknown,
          )
          .toList(growable: false);
      final salesMinutes = _sum(validActivities, WorkCategory.sales);
      final operationsMinutes = _sum(validActivities, WorkCategory.operations);
      final otherMinutes = _sum(validActivities, WorkCategory.other);
      final loggedMinutes = salesMinutes + operationsMinutes + otherMinutes;

      totalBooked += booked;
      totalWon += won.length;
      totalLost += lost.length;
      allCycleDays.addAll(cycleDays);

      reps.add(
        RepPerformance(
          user: user,
          bookedSalesMinor: booked,
          wonDeals: won.length,
          lostDeals: lost.length,
          closedDeals: closed.length,
          winRate: safeRate(won.length, closed.length),
          targetMinor: targetMinor,
          targetAttainment: targetMinor != null && targetMinor > 0
              ? booked / targetMinor
              : null,
          targetCoverage: target,
          medianCycleDays: median(cycleDays),
          leadsAllocated: leadsAllocated,
          openPipelineMinor: openPipeline,
          salesMinutes: salesMinutes,
          operationsMinutes: operationsMinutes,
          otherMinutes: otherMinutes,
          loggedMinutes: loggedMinutes,
          coverage: safeRate(validActivities.length, activities.length),
          activitiesLogged: validActivities.length,
        ),
      );
    }

    return TeamMetrics(
      reps: reps,
      totalBookedMinor: totalBooked,
      totalTargetMinor: hasTarget ? totalTarget : null,
      attainment: hasTarget && totalTarget > 0
          ? totalBooked / totalTarget
          : null,
      winRate: safeRate(totalWon, totalWon + totalLost),
      medianCycleDays: median(allCycleDays),
      totalWonDeals: totalWon,
      totalClosedDeals: totalWon + totalLost,
      totalOpenPipelineMinor: reps.fold<int>(
        0,
        (sum, rep) => sum + rep.openPipelineMinor,
      ),
      headcount: reps.length,
    );
  }

  int _sum(List<SalesActivity> activities, WorkCategory category) => activities
      .where((activity) => activity.workCategory == category)
      .fold<int>(0, (sum, activity) => sum + (activity.durationMinutes ?? 0));
}
