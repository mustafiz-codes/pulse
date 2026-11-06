import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/analytics/analytics_bundle.dart';
import 'package:pulse/core/analytics/reporting_filter.dart';
import 'package:pulse/core/analytics/unit_metrics.dart';
import 'package:pulse/core/models/sales_dataset.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../support/demo_dataset.dart';

void main() {
  late SalesDataset ds;
  late AnalyticsBundle bundle;

  setUpAll(() async {
    tz.initializeTimeZones();
    ds = await loadDemoDataset();
    bundle = AnalyticsBundle.compute(
      dataset: ds,
      filter: const ReportingFilter(),
    );
  });

  test('all() returns 5 units in catalogue order summing to booked sales', () {
    final units = const UnitMetricsCalculator().all(bundle.scope);
    expect(units.map((u) => u.unitId), [
      'lawyer',
      'cloud',
      'hr',
      'accountant',
      'global',
    ]);
    expect(units.map((u) => u.label), [
      'Lawyer',
      'Cloud',
      'HR',
      'Accountant',
      'Global',
    ]);
    expect(
      units.fold<int>(0, (sum, u) => sum + u.bookedMinor),
      bundle.sales.bookedSalesMinor,
    );
    expect(
      units.fold<int>(0, (sum, u) => sum + u.wonCount),
      bundle.sales.wonDeals,
    );
  });

  test('detail(lawyer) products sorted desc and sum to unit booked', () {
    final detail = const UnitMetricsCalculator().detail(bundle.scope, 'lawyer');
    expect(detail.unit.unitId, 'lawyer');
    expect(
      detail.products.map((p) => p.productId).toSet(),
      ds.unitFor('lawyer').products.map((p) => p.id).toSet(),
    );
    for (var i = 1; i < detail.products.length; i++) {
      expect(
        detail.products[i - 1].bookedMinor,
        greaterThanOrEqualTo(detail.products[i].bookedMinor),
      );
    }
    expect(
      detail.products.fold<int>(0, (s, p) => s + p.bookedMinor),
      detail.unit.bookedMinor,
    );
    expect(detail.reps, isNotEmpty);
    expect(
      detail.reps.fold<int>(0, (s, r) => s + r.bookedMinor),
      detail.unit.bookedMinor,
    );
  });

  test('bundle.units ignores active unit filter', () {
    final filtered = AnalyticsBundle.compute(
      dataset: ds,
      filter: const ReportingFilter(unitId: 'hr'),
    );
    expect(
      filtered.units.map((u) => u.bookedMinor),
      bundle.units.map((u) => u.bookedMinor),
    );
  });

  test('previous period booked is filled', () {
    expect(bundle.units.any((u) => u.previousBookedMinor > 0), isTrue);
  });
}
