import '../models/enums.dart';
import '../utils/labels.dart';
import 'analytics_scope.dart';
import 'math_utils.dart';

class StageDwellStat {
  const StageDwellStat({
    required this.stage,
    required this.medianDays,
    required this.meanDays,
    required this.sampleCount,
    required this.dealCount,
  });

  final DealStage stage;
  final double medianDays;
  final double meanDays;
  final int sampleCount;
  final int dealCount;
}

class CohortConversion {
  const CohortConversion({
    required this.label,
    required this.start,
    required this.end,
    required this.totalLeads,
    required this.contacted,
    required this.qualified,
    required this.opportunity,
    required this.won,
    required this.medianLeadToWinDays,
    required this.provisional,
  });

  final String label;
  final DateTime start;
  final DateTime end;
  final int totalLeads;
  final int contacted;
  final int qualified;
  final int opportunity;
  final int won;
  final double? medianLeadToWinDays;
  final bool provisional;

  double? get contactedRate => safeRate(contacted, totalLeads);
  double? get qualifiedRate => safeRate(qualified, totalLeads);
  double? get opportunityRate => safeRate(opportunity, totalLeads);
  double? get conversionRate => safeRate(won, totalLeads);
  double? get opportunityToWinRate => safeRate(won, opportunity);
}

class ConversionMetrics {
  const ConversionMetrics({
    required this.stageDwells,
    required this.slowestStage,
    required this.unavailableStageHistory,
    required this.medianFirstResponseHours,
    required this.firstResponseSample,
    required this.uncontactedLeads,
    required this.selectedCohort,
    required this.maturedCohort,
  });

  final List<StageDwellStat> stageDwells;
  final StageDwellStat? slowestStage;
  final int unavailableStageHistory;
  final double? medianFirstResponseHours;
  final int firstResponseSample;
  final int uncontactedLeads;
  final CohortConversion selectedCohort;
  final CohortConversion maturedCohort;

  double? get firstResponseCoverage =>
      safeRate(firstResponseSample, selectedCohort.totalLeads);

  bool get hasStageData => stageDwells.isNotEmpty;
}

class ConversionMetricsCalculator {
  const ConversionMetricsCalculator();

  ConversionMetrics compute(AnalyticsScope scope) {
    final stageDays = <DealStage, List<double>>{};
    final stageDeals = <DealStage, Set<String>>{};
    var unavailable = 0;

    final deals = scope.dataset.deals.where((deal) {
      if (!scope.matchesDeal(deal, applyStage: false)) return false;
      if (!deal.createdAt.isBefore(scope.window.end)) return false;
      if (deal.closedAt != null &&
          !deal.closedAt!.isAfter(scope.window.start)) {
        return false;
      }
      return true;
    });

    for (final deal in deals) {
      final events = scope.dataset.stageEventsFor(deal.id);
      if (events.isEmpty) {
        unavailable++;
        continue;
      }
      for (var i = 0; i < events.length; i++) {
        final event = events[i];
        final stage = event.toStage;
        if (stage.isTerminal) continue;
        final end = i + 1 < events.length
            ? events[i + 1].occurredAt
            : deal.closedAt ?? scope.asOf;
        final days = end.difference(event.occurredAt).inMinutes / (60 * 24);
        if (days < 0) continue;
        stageDays.putIfAbsent(stage, () => <double>[]).add(days);
        stageDeals.putIfAbsent(stage, () => <String>{}).add(deal.id);
      }
    }

    final stageDwells = <StageDwellStat>[];
    for (final stage in DealStage.values) {
      if (stage.isTerminal) continue;
      final values = stageDays[stage];
      if (values == null || values.isEmpty) continue;
      stageDwells.add(
        StageDwellStat(
          stage: stage,
          medianDays: median(values) ?? 0,
          meanDays: mean(values) ?? 0,
          sampleCount: values.length,
          dealCount: stageDeals[stage]?.length ?? 0,
        ),
      );
    }

    final eligibleForSlowest = stageDwells
        .where((stat) => stat.sampleCount >= 5)
        .toList();
    eligibleForSlowest.sort((a, b) => b.medianDays.compareTo(a.medianDays));
    final slowestStage = eligibleForSlowest.isEmpty
        ? null
        : eligibleForSlowest.first;

    final leads = scope.leadsCreatedInWindow.toList(growable: false);
    final firstResponse = <double>[
      for (final lead in leads)
        if (lead.firstContactedAt != null)
          lead.firstContactedAt!.difference(lead.createdAt).inMinutes / 60,
    ];

    return ConversionMetrics(
      stageDwells: stageDwells,
      slowestStage: slowestStage,
      unavailableStageHistory: unavailable,
      medianFirstResponseHours: median(firstResponse),
      firstResponseSample: firstResponse.length,
      uncontactedLeads: leads
          .where((lead) => lead.firstContactedAt == null)
          .length,
      selectedCohort: _cohort(
        scope,
        start: scope.window.start,
        end: scope.window.end,
        label: 'Selected cohort',
      ),
      maturedCohort: _cohort(
        scope,
        start: scope.asOf.subtract(const Duration(days: 365)),
        end: scope.asOf.subtract(const Duration(days: 90)),
        label: 'Matured cohort (90+ days)',
      ),
    );
  }

  CohortConversion _cohort(
    AnalyticsScope scope, {
    required DateTime start,
    required DateTime end,
    required String label,
  }) {
    final leads = scope.dataset.leads
        .where((lead) {
          return !lead.createdAt.isBefore(start) &&
              lead.createdAt.isBefore(end) &&
              scope.matchesLead(lead);
        })
        .toList(growable: false);

    var contacted = 0;
    var qualified = 0;
    var opportunity = 0;
    var won = 0;
    final leadToWin = <double>[];

    for (final lead in leads) {
      if (lead.firstContactedAt != null) contacted++;
      final converted = lead.convertedDealId != null;
      if (converted ||
          lead.status == LeadStatus.qualified ||
          lead.status == LeadStatus.converted) {
        qualified++;
      }
      if (converted) {
        opportunity++;
        final deal = scope.dataset.dealsById[lead.convertedDealId];
        if (deal != null && deal.outcome == DealOutcome.won) {
          won++;
          if (deal.closedAt != null) {
            leadToWin.add(
              deal.closedAt!.difference(lead.createdAt).inMinutes / (60 * 24),
            );
          }
        }
      }
    }

    return CohortConversion(
      label: label,
      start: start,
      end: end,
      totalLeads: leads.length,
      contacted: contacted,
      qualified: qualified,
      opportunity: opportunity,
      won: won,
      medianLeadToWinDays: median(leadToWin),
      provisional: scope.asOf.difference(end).inDays < 90,
    );
  }
}
