import 'package:timezone/timezone.dart' as tz;

import '../models/deal.dart';
import '../models/enums.dart';
import '../models/sales_dataset.dart';
import '../utils/labels.dart';
import 'analytics_scope.dart';
import 'conversion_metrics.dart';
import 'insight_rules.dart';
import 'math_utils.dart';
import 'needs_attention.dart';
import 'reporting_filter.dart';
import 'sales_metrics.dart';
import 'team_metrics.dart';
import 'unit_metrics.dart';
import 'workload_metrics.dart';

class MonthlySalesPoint {
  const MonthlySalesPoint({
    required this.monthStart,
    required this.label,
    required this.bookedMinor,
    required this.wonDeals,
    required this.targetMinor,
    required this.missingTargets,
  });

  final DateTime monthStart;
  final String label;
  final int bookedMinor;
  final int wonDeals;
  final int? targetMinor;
  final int missingTargets;
}

class PipelineStageSummary {
  const PipelineStageSummary({
    required this.stage,
    required this.dealCount,
    required this.valueMinor,
    required this.stalledCount,
    required this.medianDaysInStage,
  });

  final DealStage stage;
  final int dealCount;
  final int valueMinor;
  final int stalledCount;
  final double? medianDaysInStage;

  bool get isEmpty => dealCount == 0;
}

class SourceSummary {
  const SourceSummary({
    required this.source,
    required this.leads,
    required this.contacted,
    required this.converted,
    required this.won,
    required this.medianFirstResponseHours,
  });

  final LeadSource source;
  final int leads;
  final int contacted;
  final int converted;
  final int won;
  final double? medianFirstResponseHours;

  double? get contactRate => safeRate(contacted, leads);
  double? get conversionRate => safeRate(won, leads);
}

/// Immutable snapshot of every derived metric for one filter context.
///
/// Screens consume this single object so numbers cannot drift between cards,
/// charts and lists. Previous-period metrics are computed with the same
/// context and an equal-length preceding window.
class AnalyticsBundle {
  const AnalyticsBundle({
    required this.dataset,
    required this.filter,
    required this.scope,
    required this.window,
    required this.previousWindow,
    required this.sales,
    required this.previousSales,
    required this.conversion,
    required this.workload,
    required this.previousWorkload,
    required this.team,
    required this.units,
    required this.insights,
    required this.attention,
    required this.monthlySeries,
    required this.pipelineStages,
    required this.sources,
    required this.stageEnteredCounts,
  });

  final SalesDataset dataset;
  final ReportingFilter filter;
  final AnalyticsScope scope;
  final ReportWindow window;
  final ReportWindow previousWindow;
  final SalesMetrics sales;
  final SalesMetrics previousSales;
  final ConversionMetrics conversion;
  final WorkloadMetrics workload;
  final WorkloadMetrics previousWorkload;
  final TeamMetrics team;

  /// Every unit's figures for the window, ignoring any unit filter.
  final List<UnitPerformance> units;
  final List<Insight> insights;
  final List<AttentionItem> attention;
  final List<MonthlySalesPoint> monthlySeries;
  final List<PipelineStageSummary> pipelineStages;
  final List<SourceSummary> sources;
  final Map<DealStage, int> stageEnteredCounts;

  factory AnalyticsBundle.compute({
    required SalesDataset dataset,
    required ReportingFilter filter,
  }) {
    final window = filter.resolveWindow(dataset.manifest);
    final scope = AnalyticsScope(
      dataset: dataset,
      filter: filter,
      window: window,
    );
    final previousScope = scope.previous();

    const salesCalculator = SalesMetricsCalculator();
    const conversionCalculator = ConversionMetricsCalculator();
    const workloadCalculator = WorkloadMetricsCalculator();
    const teamCalculator = TeamMetricsCalculator();
    const insightCalculator = InsightCalculator();
    const attentionCalculator = AttentionCalculator();

    final sales = salesCalculator.compute(scope);
    final previousSales = salesCalculator.compute(previousScope);
    final conversion = conversionCalculator.compute(scope);
    final workload = workloadCalculator.compute(scope);
    final previousWorkload = workloadCalculator.compute(previousScope);
    final team = teamCalculator.compute(scope);

    return AnalyticsBundle(
      dataset: dataset,
      filter: filter,
      scope: scope,
      window: window,
      previousWindow: previousScope.window,
      sales: sales,
      previousSales: previousSales,
      conversion: conversion,
      workload: workload,
      previousWorkload: previousWorkload,
      team: team,
      units: const UnitMetricsCalculator().all(scope),
      insights: insightCalculator.compute(
        scope: scope,
        sales: sales,
        previousSales: previousSales,
        conversion: conversion,
        workload: workload,
        previousWorkload: previousWorkload,
      ),
      attention: attentionCalculator.compute(scope),
      monthlySeries: _monthlySeries(scope),
      pipelineStages: _pipelineStages(scope),
      sources: _sourceSummaries(scope),
      stageEnteredCounts: _stageEntryCounts(scope),
    );
  }

  int get bookedSalesDeltaMinor =>
      sales.bookedSalesMinor - previousSales.bookedSalesMinor;

  double? get bookedSalesDeltaRate {
    if (previousSales.bookedSalesMinor == 0) return null;
    return bookedSalesDeltaMinor / previousSales.bookedSalesMinor;
  }

  int get wonDealsDelta => sales.wonDeals - previousSales.wonDeals;

  int get closedDealsDelta => sales.closedDeals - previousSales.closedDeals;

  double? get winRateDeltaPoints {
    final current = sales.winRate;
    final previous = previousSales.winRate;
    if (current == null || previous == null) return null;
    return (current - previous) * 100;
  }

  double? get attainmentDeltaPoints {
    final current = sales.targetAttainment;
    final previous = previousSales.targetAttainment;
    if (current == null || previous == null) return null;
    return (current - previous) * 100;
  }

  double? get leadToWinDeltaDays {
    final current = sales.medianLeadToWinDays;
    final previous = previousSales.medianLeadToWinDays;
    if (current == null || previous == null) return null;
    return current - previous;
  }

  double? get firstResponseDeltaHours {
    final current = sales.medianFirstResponseHours;
    final previous = previousSales.medianFirstResponseHours;
    if (current == null || previous == null) return null;
    return current - previous;
  }

  double? get opsShareDeltaPoints {
    final current = workload.operationsShare;
    final previous = previousWorkload.operationsShare;
    if (current == null || previous == null) return null;
    return (current - previous) * 100;
  }

  double? get medianCycleDeltaDays {
    final current = sales.medianDealCycleDays;
    final previous = previousSales.medianDealCycleDays;
    if (current == null || previous == null) return null;
    return current - previous;
  }

  String get asOfLabel => dataset.manifest.asOf.toIso8601String();

  DealStage? get slowestStage => conversion.slowestStage?.stage;

  bool get hasAnyData =>
      sales.totalDeals > 0 ||
      sales.leadsCreated > 0 ||
      sales.openDealsCount > 0 ||
      workload.eligibleActivities > 0;

  static List<MonthlySalesPoint> _monthlySeries(AnalyticsScope scope) {
    final dataset = scope.dataset;
    final location = _location(dataset.manifest.timezone);
    final asOfLocal = tz.TZDateTime.from(dataset.manifest.asOf, location);
    final owners = scope.matchingUsers.map((user) => user.id).toSet();
    final points = <MonthlySalesPoint>[];

    for (var offset = 11; offset >= 0; offset--) {
      final monthStart = tz.TZDateTime(
        location,
        asOfLocal.year,
        asOfLocal.month - offset,
        1,
      );
      final monthEnd = tz.TZDateTime(
        location,
        monthStart.year,
        monthStart.month + 1,
        1,
      );
      final startUtc = monthStart.toUtc();
      final endUtc = monthEnd.toUtc();

      var booked = 0;
      var won = 0;
      for (final deal in dataset.deals) {
        if (deal.outcome != DealOutcome.won || deal.closedAt == null) continue;
        if (!scope.matchesDeal(deal, applyStage: false)) continue;
        if (deal.closedAt!.isBefore(startUtc) ||
            !deal.closedAt!.isBefore(endUtc)) {
          continue;
        }
        booked += deal.valueMinor;
        won++;
      }

      final monthLabel =
          '${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}';
      var targetTotal = 0;
      var missing = 0;
      for (final ownerId in owners) {
        final target = dataset.targetFor(ownerId, monthLabel);
        if (target == null) {
          missing++;
        } else {
          targetTotal += target.wonValueTargetMinor;
        }
      }

      points.add(
        MonthlySalesPoint(
          monthStart: startUtc,
          label: _monthLabel(monthStart),
          bookedMinor: booked,
          wonDeals: won,
          // Targets are per rep: a unit-filtered view has none, never a sum
          // of whole-rep targets set against unit-only sales.
          targetMinor:
              scope.filter.unitId != null || owners.isEmpty || targetTotal == 0
              ? null
              : targetTotal,
          missingTargets: missing,
        ),
      );
    }
    return List.unmodifiable(points);
  }

  static List<PipelineStageSummary> _pipelineStages(AnalyticsScope scope) {
    final stages = <DealStage, List<Deal>>{};
    for (final deal in scope.openDealsSnapshot) {
      stages.putIfAbsent(deal.stage, () => <Deal>[]).add(deal);
    }
    return List.unmodifiable([
      for (final stage in SalesDataset.pipelineStages)
        if (stages[stage] != null && stages[stage]!.isNotEmpty)
          PipelineStageSummary(
            stage: stage,
            dealCount: stages[stage]!.length,
            valueMinor: stages[stage]!.fold<int>(
              0,
              (total, deal) => total + deal.valueMinor,
            ),
            stalledCount: stages[stage]!.where((deal) {
              final activityAge = scope.lastActivityAgeDays(deal);
              return scope.stageAgeDays(deal) > 14 ||
                  (activityAge != null && activityAge > 14);
            }).length,
            medianDaysInStage: median(stages[stage]!.map(scope.stageAgeDays)),
          ),
    ]);
  }

  static List<SourceSummary> _sourceSummaries(AnalyticsScope scope) {
    final leads = scope.leadsCreatedInWindow.toList(growable: false);
    return List.unmodifiable([
      for (final source in LeadSource.values)
        if (leads.any((lead) => lead.source == source))
          SourceSummary(
            source: source,
            leads: leads.where((lead) => lead.source == source).length,
            contacted: leads
                .where(
                  (lead) =>
                      lead.source == source && lead.firstContactedAt != null,
                )
                .length,
            converted: leads
                .where(
                  (lead) =>
                      lead.source == source && lead.convertedDealId != null,
                )
                .length,
            won: leads.where((lead) {
              if (lead.source != source || lead.convertedDealId == null) {
                return false;
              }
              final deal = scope.dataset.dealsById[lead.convertedDealId];
              return deal != null && deal.outcome == DealOutcome.won;
            }).length,
            medianFirstResponseHours: median(
              leads
                  .where(
                    (lead) =>
                        lead.source == source && lead.firstContactedAt != null,
                  )
                  .map(
                    (lead) =>
                        lead.firstContactedAt!
                            .difference(lead.createdAt)
                            .inMinutes /
                        60,
                  ),
            ),
          ),
    ]);
  }

  static Map<DealStage, int> _stageEntryCounts(AnalyticsScope scope) {
    final counts = <DealStage, int>{};
    for (final deal in scope.dataset.deals) {
      if (!scope.matchesDeal(deal, applyStage: false)) continue;
      if (!deal.createdAt.isBefore(scope.window.end)) continue;
      if (deal.closedAt != null &&
          !deal.closedAt!.isAfter(scope.window.start)) {
        continue;
      }
      final events = scope.dataset.stageEventsFor(deal.id);
      if (events.isEmpty) continue;
      for (final event in events) {
        if (event.occurredAt.isBefore(scope.window.start) ||
            !event.occurredAt.isBefore(scope.window.end)) {
          continue;
        }
        counts.update(event.toStage, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    return Map.unmodifiable(counts);
  }

  static tz.Location _location(String timezone) {
    try {
      return tz.getLocation(timezone);
    } catch (_) {
      return tz.UTC;
    }
  }

  static String _monthLabel(tz.TZDateTime month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${names[month.month - 1]} ${month.year.toString().substring(2)}';
  }
}

extension DealStageSummaryLabel on PipelineStageSummary {
  String get label => stage.label;
}
