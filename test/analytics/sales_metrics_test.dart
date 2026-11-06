import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/analytics/sales_metrics.dart';
import 'package:pulse/core/models/enums.dart';
import 'package:pulse/core/utils/currency_format.dart';

import '../support/fixture.dart';

void main() {
  group('closed-deal win rate', () {
    test('is unavailable when no deals closed', () {
      final dataset = buildDataset(
        deals: [
          testDeal(
            id: 'open_1',
            valueMinor: 500000,
            stage: DealStage.proposal,
            outcome: DealOutcome.open,
            createdAt: DateTime.utc(2026, 9, 1),
          ),
        ],
      );

      final metrics = const SalesMetricsCalculator().compute(
        testScope(dataset),
      );

      expect(metrics.closedDeals, 0);
      expect(metrics.winRate, isNull);
      expect(metrics.hasClosedDeals, isFalse);
    });

    test('is 50% for one won and one lost deal', () {
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
            id: 'lost_1',
            valueMinor: 900000,
            stage: DealStage.lost,
            outcome: DealOutcome.lost,
            createdAt: DateTime.utc(2026, 9, 2),
            closedAt: DateTime.utc(2026, 10, 12),
          ),
        ],
      );

      final metrics = const SalesMetricsCalculator().compute(
        testScope(dataset),
      );

      expect(metrics.wonDeals, 1);
      expect(metrics.lostDeals, 1);
      expect(metrics.closedDeals, 2);
      expect(metrics.winRate, 0.5);
      expect(metrics.bookedSalesMinor, 100000);
    });
  });

  test('first response uses exact instants, not whole-day arithmetic', () {
    final dataset = buildDataset(
      leads: [
        testLead(
          id: 'lead_1',
          createdAt: DateTime.utc(2026, 10, 1, 9),
          firstContactedAt: DateTime.utc(2026, 10, 2, 10),
          status: LeadStatus.contacted,
        ),
      ],
    );

    final metrics = const SalesMetricsCalculator().compute(testScope(dataset));

    expect(metrics.medianFirstResponseHours, 25);
    expect(metrics.firstResponseSample, 1);
    expect(metrics.uncontactedLeads, 0);
  });

  test('open stage age is exact from the recorded stage instant', () {
    final dataset = buildDataset(
      deals: [
        testDeal(
          id: 'open_1',
          valueMinor: 500000,
          stage: DealStage.proposal,
          outcome: DealOutcome.open,
          createdAt: DateTime.utc(2026, 10, 1),
        ),
      ],
      stageEvents: [
        testStageEvent(
          id: 'event_1',
          dealId: 'open_1',
          occurredAt: DateTime.utc(2026, 10, 20, 12),
          toStage: DealStage.proposal,
        ),
      ],
    );

    final age = testScope(dataset).stageAgeDays(dataset.deals.single);

    expect(age, closeTo(11.4993, 0.0001));
  });

  test('integer pence formats exactly as GBP without float rounding', () {
    expect(formatMoneyMinor(123456, pence: true), '£1,234.56');
    expect(formatMoneyMinor(1, pence: true), '£0.01');
    expect(formatMoneyMinor(100), '£1');
    expect(formatMoneyMinorSigned(-123456, pence: true), '−£1,234.56');
  });
}
