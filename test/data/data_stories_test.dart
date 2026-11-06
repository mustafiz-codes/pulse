import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/analytics/analytics_bundle.dart';
import 'package:pulse/core/analytics/reporting_filter.dart';
import 'package:pulse/core/models/deal.dart';
import 'package:pulse/core/models/enums.dart';
import 'package:pulse/core/models/sales_dataset.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../support/demo_dataset.dart';

/// Spec 6.2 value ranges per unit, in minor units (pence).
const _unitRanges = <String, (int, int)>{
  'lawyer': (150000, 800000),
  'cloud': (200000, 1200000),
  'hr': (80000, 400000),
  'accountant': (30000, 250000),
  'global': (300000, 1500000),
};

const _individualProducts = {
  'visa',
  'ilr',
  'citizenship',
  'appeal',
  'ar',
  'jr',
};

void main() {
  late SalesDataset ds;
  late AnalyticsBundle october;

  setUpAll(() async {
    tz.initializeTimeZones();
    ds = await loadDemoDataset();
    october = AnalyticsBundle.compute(
      dataset: ds,
      filter: const ReportingFilter(),
    );
  });

  String unitOf(Deal d) => ds.unitIdOf(d.productId);

  Map<String, int> octoberBookedByUnit() {
    final totals = {for (final id in ds.unitIds) id: 0};
    for (final deal in october.scope.wonDealsInWindow) {
      totals[unitOf(deal)] = totals[unitOf(deal)]! + deal.valueMinor;
    }
    return totals;
  }

  test('october booked sales is between £60k and £100k', () {
    expect(october.sales.bookedSalesMinor, inInclusiveRange(6000000, 10000000));
  });

  test('every deal value is inside its unit range', () {
    for (final deal in ds.deals) {
      final (min, max) = _unitRanges[unitOf(deal)]!;
      expect(deal.valueMinor, inInclusiveRange(min, max), reason: deal.id);
    }
  });

  test('lawyer is the biggest and accountant the smallest October unit', () {
    final totals = octoberBookedByUnit();
    final ranked = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    expect(ranked.first.key, 'lawyer', reason: '$totals');
    expect(ranked.last.key, 'accountant', reason: '$totals');
  });

  test('cloud has the largest open pipeline value', () {
    final open = {for (final id in ds.unitIds) id: 0};
    for (final deal in ds.deals.where((d) => d.isOpen)) {
      open[unitOf(deal)] = open[unitOf(deal)]! + deal.valueMinor;
    }
    final top = open.entries.reduce((a, b) => a.value >= b.value ? a : b);
    expect(top.key, 'cloud', reason: '$open');
  });

  test('global has the fewest deals overall', () {
    final counts = {for (final id in ds.unitIds) id: 0};
    for (final deal in ds.deals) {
      counts[unitOf(deal)] = counts[unitOf(deal)]! + 1;
    }
    final fewest = counts.entries.reduce((a, b) => a.value <= b.value ? a : b);
    expect(fewest.key, 'global', reason: '$counts');
  });

  test('Mamun has the single largest October win', () {
    final wins = october.scope.wonDealsInWindow.toList()
      ..sort((a, b) => b.valueMinor.compareTo(a.valueMinor));
    expect(ds.userFor(wins.first.ownerId)!.displayName, 'Mamun');
    expect(wins[1].valueMinor, lessThan(wins.first.valueMinor));
  });

  test('Sunny is ≥110% of October target and one rep is below 90%', () {
    double attainment(String name) {
      final user = ds.users.firstWhere((u) => u.displayName == name);
      final won = october.scope.wonDealsInWindow
          .where((d) => d.ownerId == user.id)
          .fold<int>(0, (sum, d) => sum + d.valueMinor);
      final target = ds.targetFor(user.id, '2026-10')!.wonValueTargetMinor;
      return won / target;
    }

    final all = {
      for (final u in ds.users) u.displayName: attainment(u.displayName),
    };
    expect(all['Sunny'], greaterThanOrEqualTo(1.10), reason: '$all');
    expect(all.values.any((a) => a < 0.90), isTrue, reason: '$all');
    for (final a in all.values) {
      expect(a, inInclusiveRange(0.75, 1.35), reason: '$all');
    }
    final teamTarget = ds.users.fold<int>(
      0,
      (sum, u) => sum + ds.targetFor(u.id, '2026-10')!.wonValueTargetMinor,
    );
    expect(teamTarget, inInclusiveRange(7000000, 9500000));
  });

  test('individual products always sold to individuals', () {
    for (final lead in ds.leads) {
      final kind = ds.accountFor(lead.accountId)!.kind;
      expect(
        kind,
        _individualProducts.contains(lead.productId)
            ? AccountKind.individual
            : AccountKind.business,
        reason: lead.id,
      );
    }
  });

  test('JR median proposal dwell exceeds every other product (n ≥ 5)', () {
    final dwell = <String, List<double>>{};
    for (final deal in ds.deals) {
      final events = ds.stageEventsFor(deal.id);
      for (var i = 0; i < events.length; i++) {
        if (events[i].toStage != DealStage.proposal) continue;
        final end = i + 1 < events.length
            ? events[i + 1].occurredAt
            : (deal.isOpen ? ds.manifest.asOf : null);
        if (end == null) continue;
        dwell
            .putIfAbsent(deal.productId, () => [])
            .add(end.difference(events[i].occurredAt).inHours / 24);
      }
    }
    double median(List<double> xs) {
      final s = [...xs]..sort();
      return s[s.length ~/ 2];
    }

    final medians = {
      for (final e in dwell.entries)
        if (e.value.length >= 5) e.key: median(e.value),
    };
    expect(medians.containsKey('jr'), isTrue, reason: '$medians');
    for (final e in medians.entries) {
      if (e.key == 'jr') continue;
      expect(medians['jr']!, greaterThan(e.value), reason: '$medians');
    }
  });

  test('conversion_bottleneck focus deal is an open JR deal in proposal', () {
    final scenario = ds.scenarios.firstWhere(
      (s) => s.id == 'conversion_bottleneck',
    );
    expect(scenario.unitId, 'lawyer');
    final deal = ds.dealFor(scenario.focusDealId!)!;
    expect(deal.productId, 'jr');
    expect(deal.isOpen, isTrue);
    expect(deal.stage, DealStage.proposal);
  });

  test('September is a believable previous month (55–95% of October)', () {
    final previous = october.previousSales.bookedSalesMinor;
    final current = october.sales.bookedSalesMinor;
    expect(
      previous / current,
      inInclusiveRange(0.55, 0.95),
      reason: 'Sep $previous vs Oct $current',
    );
  });

  test('October win rate is believable (45–75%)', () {
    expect(
      october.sales.winRate!,
      inInclusiveRange(0.45, 0.75),
      reason:
          '${october.sales.wonDeals} won / ${october.sales.closedDeals} closed',
    );
  });

  test('October median lead-to-win is under 100 days', () {
    expect(october.sales.medianLeadToWinDays!, lessThan(100));
  });

  test('JR is at most half of Lawyer October wins', () {
    final lawyerWins = october.scope.wonDealsInWindow
        .where((d) => unitOf(d) == 'lawyer')
        .toList();
    final jr = lawyerWins.where((d) => d.productId == 'jr').length;
    expect(
      jr * 2,
      lessThanOrEqualTo(lawyerWins.length),
      reason: '$jr JR of ${lawyerWins.length} Lawyer wins',
    );
  });

  test(
    'every unit has at least one October loss or open deal (no 100% units)',
    () {
      for (final unit in ds.unitIds) {
        final closed = october.scope.dealsClosedInWindow
            .where((d) => unitOf(d) == unit)
            .toList();
        if (closed.length < 3) continue;
        expect(closed.any((d) => d.isLost), isTrue, reason: unit);
      }
    },
  );
}
