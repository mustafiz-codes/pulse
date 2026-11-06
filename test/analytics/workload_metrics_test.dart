import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/analytics/workload_metrics.dart';
import 'package:pulse/core/models/enums.dart';

import '../support/fixture.dart';

void main() {
  test('logged-time shares use valid minutes only', () {
    final day = DateTime.utc(2026, 10, 12, 9);
    final dataset = buildDataset(
      activities: [
        testActivity(
          id: 'sales_1',
          category: WorkCategory.sales,
          durationMinutes: 180,
          startedAt: day,
        ),
        testActivity(
          id: 'ops_1',
          category: WorkCategory.operations,
          durationMinutes: 90,
          startedAt: day.add(const Duration(hours: 1)),
        ),
        testActivity(
          id: 'other_1',
          category: WorkCategory.other,
          durationMinutes: 30,
          startedAt: day.add(const Duration(hours: 2)),
        ),
      ],
    );

    final metrics = const WorkloadMetricsCalculator().compute(
      testScope(dataset),
    );

    expect(metrics.totalMinutes, 300);
    expect(metrics.salesMinutes, 180);
    expect(metrics.operationsMinutes, 90);
    expect(metrics.otherMinutes, 30);
    expect(metrics.salesShare, closeTo(0.60, 1e-9));
    expect(metrics.operationsShare, closeTo(0.30, 1e-9));
    expect(metrics.otherShare, closeTo(0.10, 1e-9));
  });

  test(
    'missing, estimated and unclassified time is excluded and disclosed',
    () {
      final day = DateTime.utc(2026, 10, 12, 9);
      final dataset = buildDataset(
        activities: [
          testActivity(
            id: 'sales_1',
            category: WorkCategory.sales,
            durationMinutes: 180,
            startedAt: day,
          ),
          testActivity(
            id: 'ops_1',
            category: WorkCategory.operations,
            durationMinutes: 90,
            startedAt: day.add(const Duration(hours: 1)),
          ),
          testActivity(
            id: 'other_1',
            category: WorkCategory.other,
            durationMinutes: 30,
            startedAt: day.add(const Duration(hours: 2)),
          ),
          testActivity(
            id: 'missing_1',
            category: WorkCategory.sales,
            durationMinutes: null,
            startedAt: day.add(const Duration(hours: 3)),
            timeQuality: TimeQuality.notRecorded,
          ),
          testActivity(
            id: 'estimated_1',
            category: WorkCategory.operations,
            durationMinutes: 45,
            startedAt: day.add(const Duration(hours: 4)),
            timeQuality: TimeQuality.estimated,
          ),
          testActivity(
            id: 'unknown_1',
            category: WorkCategory.unknown,
            durationMinutes: 25,
            startedAt: day.add(const Duration(hours: 5)),
          ),
        ],
      );

      final metrics = const WorkloadMetricsCalculator().compute(
        testScope(dataset),
      );

      expect(metrics.totalMinutes, 300);
      expect(metrics.validActivities, 3);
      expect(metrics.eligibleActivities, 6);
      expect(metrics.missingDurationActivities, 1);
      expect(metrics.estimatedActivities, 1);
      expect(metrics.unknownCategoryActivities, 1);
      expect(metrics.coverage, closeTo(0.5, 1e-9));
    },
  );

  test('no logged time produces unavailable shares, not zero', () {
    final dataset = buildDataset(
      activities: [
        testActivity(
          id: 'missing_1',
          category: WorkCategory.sales,
          startedAt: DateTime.utc(2026, 10, 12),
          timeQuality: TimeQuality.notRecorded,
        ),
      ],
    );

    final metrics = const WorkloadMetricsCalculator().compute(
      testScope(dataset),
    );

    expect(metrics.totalMinutes, 0);
    expect(metrics.operationsShare, isNull);
    expect(metrics.salesShare, isNull);
    expect(metrics.insufficient, isTrue);
  });

  group('activitiesForCategory', () {
    final day = DateTime.utc(2026, 10, 12, 9);

    test('includes missing-duration records, newest first', () {
      final dataset = buildDataset(
        activities: [
          testActivity(
            id: 'sales_old',
            category: WorkCategory.sales,
            durationMinutes: 180,
            startedAt: day,
          ),
          testActivity(
            id: 'sales_missing',
            category: WorkCategory.sales,
            startedAt: day.add(const Duration(days: 2)),
            timeQuality: TimeQuality.notRecorded,
          ),
          testActivity(
            id: 'sales_new',
            category: WorkCategory.sales,
            durationMinutes: 90,
            startedAt: day.add(const Duration(days: 3)),
          ),
          testActivity(
            id: 'ops_1',
            category: WorkCategory.operations,
            durationMinutes: 60,
            startedAt: day,
          ),
        ],
      );

      final result = activitiesForCategory(
        testScope(dataset),
        WorkCategory.sales,
      );

      expect(result.map((a) => a.id), [
        'sales_new',
        'sales_missing',
        'sales_old',
      ]);
    });

    test('a rep with no operations logs gets an empty list', () {
      final dataset = buildDataset(
        activities: [
          testActivity(
            id: 'sales_1',
            category: WorkCategory.sales,
            durationMinutes: 30,
            startedAt: day,
          ),
        ],
      );

      expect(
        activitiesForCategory(testScope(dataset), WorkCategory.operations),
        isEmpty,
      );
    });

    test('excludes activities outside the reporting window', () {
      final dataset = buildDataset(
        activities: [
          testActivity(
            id: 'ops_sept',
            category: WorkCategory.operations,
            durationMinutes: 30,
            startedAt: DateTime.utc(2026, 9, 10),
          ),
        ],
      );

      expect(
        activitiesForCategory(testScope(dataset), WorkCategory.operations),
        isEmpty,
      );
    });
  });
}
