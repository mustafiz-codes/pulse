import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/analytics/analytics_bundle.dart';
import 'package:pulse/core/analytics/reporting_filter.dart';
import 'package:pulse/core/models/enums.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../support/fixture.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  test('October window respects Europe/London daylight saving', () {
    final dataset = buildDataset(timezone: 'Europe/London');

    final window = const ReportingFilter().resolveWindow(dataset.manifest);

    expect(window.label, 'October 2026');
    expect(window.start, DateTime.utc(2026, 9, 30, 23));
    expect(window.end, DateTime.utc(2026, 11, 1));
  });

  test('previous period is an equal-length window immediately before', () {
    final dataset = buildDataset(timezone: 'Europe/London');
    final window = const ReportingFilter().resolveWindow(dataset.manifest);
    final previous = window.previous;

    expect(previous.end, window.start);
    expect(previous.duration, window.duration);
    expect(previous.label, 'Previous period');
  });

  test('quarter preset starts three calendar months back', () {
    final dataset = buildDataset(timezone: 'Europe/London');

    final window = const ReportingFilter(
      preset: PeriodPreset.quarter,
    ).resolveWindow(dataset.manifest);

    expect(window.label, 'Aug – Oct 2026');
    expect(window.start, DateTime.utc(2026, 7, 31, 23));
    expect(window.end, DateTime.utc(2026, 11, 1));
  });

  test('stage filter narrows the open snapshot but not closed KPIs', () {
    final dataset = buildDataset(
      deals: [
        testDeal(
          id: 'won_1',
          valueMinor: 100000,
          stage: DealStage.won,
          outcome: DealOutcome.won,
          createdAt: DateTime.utc(2026, 9, 1),
          closedAt: DateTime.utc(2026, 10, 10),
        ),
        testDeal(
          id: 'open_proposal',
          valueMinor: 200000,
          stage: DealStage.proposal,
          outcome: DealOutcome.open,
          createdAt: DateTime.utc(2026, 9, 1),
        ),
        testDeal(
          id: 'open_discovery',
          valueMinor: 300000,
          stage: DealStage.discovery,
          outcome: DealOutcome.open,
          createdAt: DateTime.utc(2026, 9, 1),
        ),
      ],
    );

    final bundle = AnalyticsBundle.compute(
      dataset: dataset,
      filter: ReportingFilter(
        preset: PeriodPreset.custom,
        customStart: DateTime.utc(2026, 10, 1),
        customEnd: DateTime.utc(2026, 10, 31),
        stage: DealStage.proposal,
      ),
    );

    expect(bundle.sales.wonDeals, 1);
    expect(bundle.sales.bookedSalesMinor, 100000);
    expect(bundle.scope.openDealsSnapshot.map((deal) => deal.id), [
      'open_proposal',
    ]);
    expect(bundle.pipelineStages.single.stage, DealStage.proposal);
  });

  test('a single owner filter changes every scoped metric source', () {
    final dataset = buildDataset(
      users: [testUser('rep_1'), testUser('rep_2')],
      deals: [
        testDeal(
          id: 'won_1',
          ownerId: 'rep_1',
          valueMinor: 100000,
          stage: DealStage.won,
          outcome: DealOutcome.won,
          createdAt: DateTime.utc(2026, 9, 1),
          closedAt: DateTime.utc(2026, 10, 10),
        ),
        testDeal(
          id: 'won_2',
          ownerId: 'rep_2',
          valueMinor: 900000,
          stage: DealStage.won,
          outcome: DealOutcome.won,
          createdAt: DateTime.utc(2026, 9, 1),
          closedAt: DateTime.utc(2026, 10, 11),
        ),
      ],
    );

    final bundle = AnalyticsBundle.compute(
      dataset: dataset,
      filter: ReportingFilter(
        preset: PeriodPreset.custom,
        customStart: DateTime.utc(2026, 10, 1),
        customEnd: DateTime.utc(2026, 10, 31),
        ownerId: 'rep_2',
      ),
    );

    expect(bundle.sales.bookedSalesMinor, 900000);
    expect(bundle.team.reps.single.user.id, 'rep_2');
    expect(bundle.monthlySeries.last.bookedMinor, 900000);
  });
}
