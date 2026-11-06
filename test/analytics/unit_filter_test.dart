import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/analytics/analytics_bundle.dart';
import 'package:pulse/core/analytics/reporting_filter.dart';
import 'package:pulse/core/analytics/target_metrics.dart';
import 'package:pulse/core/models/enums.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../support/demo_dataset.dart';
import '../support/fixture.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  final oct = DateTime.utc(2026, 10, 10);
  final dataset = buildDataset(
    users: [
      testUser('rep_c', homeUnitId: 'cloud'),
      testUser('rep_l', homeUnitId: 'lawyer'),
    ],
    leads: [
      testLead(
        id: 'lead_law',
        createdAt: oct,
        ownerId: 'rep_c',
        productId: 'visa',
      ),
      testLead(
        id: 'lead_cloud',
        createdAt: oct,
        ownerId: 'rep_l',
        productId: 'managed_it',
      ),
    ],
    deals: [
      testDeal(
        id: 'deal_law',
        leadId: 'lead_law',
        ownerId: 'rep_c',
        productId: 'visa',
        valueMinor: 200000,
        stage: DealStage.won,
        outcome: DealOutcome.won,
        createdAt: oct,
        closedAt: oct.add(const Duration(days: 5)),
      ),
      testDeal(
        id: 'deal_cloud',
        leadId: 'lead_cloud',
        ownerId: 'rep_l',
        productId: 'managed_it',
        valueMinor: 600000,
        stage: DealStage.proposal,
        outcome: DealOutcome.open,
        createdAt: oct,
      ),
    ],
    activities: [
      testActivity(
        id: 'a_deal',
        category: WorkCategory.sales,
        startedAt: oct,
        ownerId: 'rep_l',
        dealId: 'deal_law',
        durationMinutes: 30,
      ),
      testActivity(
        id: 'a_lead',
        category: WorkCategory.sales,
        startedAt: oct,
        ownerId: 'rep_c',
        leadId: 'lead_law',
        durationMinutes: 20,
      ),
      testActivity(
        id: 'a_cloud',
        category: WorkCategory.operations,
        startedAt: oct,
        ownerId: 'rep_c',
        dealId: 'deal_cloud',
        durationMinutes: 40,
      ),
      testActivity(
        id: 'a_internal',
        category: WorkCategory.other,
        startedAt: oct,
        ownerId: 'rep_l',
        durationMinutes: 60,
      ),
    ],
  );
  const lawyer = ReportingFilter(unitId: 'lawyer');

  test('unit filter keeps records of that unit, whoever owns them', () {
    final scope = testScope(dataset, filter: lawyer);
    expect(scope.contextDeals.map((d) => d.id), ['deal_law']);
    expect(scope.leadsCreatedInWindow.map((l) => l.id), ['lead_law']);
    expect(scope.matchingUsers.map((u) => u.id), ['rep_c']);
  });

  test(
    'activity linked to lawyer deal or lead included, unlinked excluded',
    () {
      final scope = testScope(dataset, filter: lawyer);
      expect(scope.activitiesInWindow.map((a) => a.id).toSet(), {
        'a_deal',
        'a_lead',
      });
      final all = testScope(dataset);
      expect(all.activitiesInWindow, hasLength(4));
    },
  );

  test('target coverage is unitFiltered when unit set', () {
    final coverage = const TargetCalculator().forScope(
      testScope(dataset, filter: lawyer),
    );
    expect(coverage.unitFiltered, isTrue);
    expect(coverage.hasTarget, isFalse);
    expect(
      const TargetCalculator().forScope(testScope(dataset)).unitFiltered,
      isFalse,
    );
  });

  test('reset_clears_unit', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(reportingFilterProvider.notifier);
    notifier.setUnit('hr');
    expect(container.read(reportingFilterProvider).unitId, 'hr');
    expect(container.read(reportingFilterProvider).hasAnyFilter, isTrue);
    notifier.reset();
    expect(container.read(reportingFilterProvider).unitId, isNull);
  });

  test('empty_unit_window_is_safe', () async {
    final demo = await loadDemoDataset();
    final bundle = AnalyticsBundle.compute(
      dataset: demo,
      filter: const ReportingFilter(
        unitId: 'global',
        preset: PeriodPreset.last7Days,
      ),
    );
    final rate = bundle.sales.winRate;
    expect(rate == null || rate.isFinite, isTrue);
    expect(bundle.units, hasLength(5));
    for (final unit in bundle.units) {
      expect(unit.bookedMinor, greaterThanOrEqualTo(0));
      expect(unit.openPipelineMinor, greaterThanOrEqualTo(0));
    }
  });
}
