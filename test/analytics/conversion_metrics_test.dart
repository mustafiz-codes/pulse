import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/analytics/conversion_metrics.dart';
import 'package:pulse/core/models/enums.dart';

import '../support/fixture.dart';

void main() {
  test('missing stage history is unavailable and disclosed', () {
    final dataset = buildDataset(
      deals: [
        testDeal(
          id: 'deal_1',
          valueMinor: 100000,
          stage: DealStage.proposal,
          outcome: DealOutcome.open,
          createdAt: DateTime.utc(2026, 10, 1),
        ),
      ],
    );

    final metrics = const ConversionMetricsCalculator().compute(
      testScope(dataset),
    );

    expect(metrics.hasStageData, isFalse);
    expect(metrics.stageDwells, isEmpty);
    expect(metrics.slowestStage, isNull);
    expect(metrics.unavailableStageHistory, 1);
  });

  test('stage dwell is measured between recorded stage events', () {
    final dataset = buildDataset(
      deals: [
        testDeal(
          id: 'deal_1',
          valueMinor: 100000,
          stage: DealStage.won,
          outcome: DealOutcome.won,
          createdAt: DateTime.utc(2026, 10, 1),
          closedAt: DateTime.utc(2026, 10, 20),
        ),
      ],
      stageEvents: [
        testStageEvent(
          id: 'event_1',
          dealId: 'deal_1',
          occurredAt: DateTime.utc(2026, 10, 1),
          toStage: DealStage.newStage,
        ),
        testStageEvent(
          id: 'event_2',
          dealId: 'deal_1',
          occurredAt: DateTime.utc(2026, 10, 10),
          fromStage: DealStage.newStage,
          toStage: DealStage.proposal,
        ),
        testStageEvent(
          id: 'event_3',
          dealId: 'deal_1',
          occurredAt: DateTime.utc(2026, 10, 20),
          fromStage: DealStage.proposal,
          toStage: DealStage.won,
        ),
      ],
    );

    final metrics = const ConversionMetricsCalculator().compute(
      testScope(dataset),
    );
    final newStage = metrics.stageDwells.firstWhere(
      (stat) => stat.stage == DealStage.newStage,
    );
    final proposal = metrics.stageDwells.firstWhere(
      (stat) => stat.stage == DealStage.proposal,
    );

    expect(metrics.unavailableStageHistory, 0);
    expect(newStage.medianDays, closeTo(9, 1e-9));
    expect(proposal.medianDays, closeTo(10, 1e-9));
    expect(proposal.sampleCount, 1);
    // A single visit is not enough evidence to crown a slowest stage.
    expect(metrics.slowestStage, isNull);
  });
}
