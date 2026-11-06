import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/analytics/team_metrics.dart';
import 'package:pulse/core/models/enums.dart';

import '../support/fixture.dart';

void main() {
  test('team win rate aggregates wins and losses, not rep averages', () {
    final dataset = buildDataset(
      users: [
        testUser('rep_1', name: 'Alex One'),
        testUser('rep_2', name: 'Blair Two'),
      ],
      deals: [
        testDeal(
          id: 'won_1',
          ownerId: 'rep_1',
          valueMinor: 100000,
          stage: DealStage.won,
          outcome: DealOutcome.won,
          createdAt: DateTime.utc(2026, 9, 1),
          closedAt: DateTime.utc(2026, 10, 5),
        ),
        testDeal(
          id: 'lost_1',
          ownerId: 'rep_2',
          valueMinor: 200000,
          stage: DealStage.lost,
          outcome: DealOutcome.lost,
          createdAt: DateTime.utc(2026, 9, 1),
          closedAt: DateTime.utc(2026, 10, 6),
        ),
        testDeal(
          id: 'lost_2',
          ownerId: 'rep_2',
          valueMinor: 300000,
          stage: DealStage.lost,
          outcome: DealOutcome.lost,
          createdAt: DateTime.utc(2026, 9, 1),
          closedAt: DateTime.utc(2026, 10, 7),
        ),
        testDeal(
          id: 'lost_3',
          ownerId: 'rep_2',
          valueMinor: 400000,
          stage: DealStage.lost,
          outcome: DealOutcome.lost,
          createdAt: DateTime.utc(2026, 9, 1),
          closedAt: DateTime.utc(2026, 10, 8),
        ),
      ],
    );

    final metrics = const TeamMetricsCalculator().compute(testScope(dataset));

    expect(metrics.totalWonDeals, 1);
    expect(metrics.totalClosedDeals, 4);
    expect(metrics.winRate, 0.25);
    expect(metrics.reps.firstWhere((rep) => rep.user.id == 'rep_1').winRate, 1);
    expect(metrics.reps.firstWhere((rep) => rep.user.id == 'rep_2').winRate, 0);
  });

  test('targets are prorated for a partial month', () {
    final dataset = buildDataset(targets: [testTarget(valueMinor: 310000)]);
    final scope = testScope(
      dataset,
      start: DateTime.utc(2026, 10, 1),
      end: DateTime.utc(2026, 10, 16),
    );

    final metrics = const TeamMetricsCalculator().compute(scope);

    // 15 of October's 31 days: 310,000 * 15 / 31 = 150,000 (rounded).
    expect(metrics.reps.single.targetMinor, 150000);
    expect(metrics.reps.single.targetCoverage.hasPartialCoverage, isFalse);
  });
}
