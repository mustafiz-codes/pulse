import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/analytics/reporting_filter.dart';
import 'package:pulse/core/analytics/unit_metrics.dart';
import 'package:pulse/core/data/providers.dart';
import 'package:pulse/core/models/sales_dataset.dart';
import 'package:pulse/features/pipeline/pipeline_screen.dart';
import 'package:pulse/features/units/unit_detail_screen.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../support/demo_dataset.dart';
import '../support/fonts.dart';
import '../support/pump_app.dart';

void main() {
  late SalesDataset dataset;

  setUpAll(() async {
    tz.initializeTimeZones();
    await loadInterFonts();
    dataset = await loadDemoDataset();
  });

  testWidgets('unit detail shows products sorted by booked value', (
    tester,
  ) async {
    await pumpApp(tester, dataset, initialLocation: '/units/lawyer');
    expect(find.byType(UnitDetailScreen), findsOneWidget);
    expect(find.text('Lawyer'), findsWidgets);
    expect(find.text('Top products'), findsOneWidget);
    final detail = ProviderScope.containerOf(
      tester.element(find.byType(UnitDetailScreen)),
    ).read(unitDetailProvider('lawyer'));
    final top = detail.products.first;
    expect(top.bookedMinor, greaterThan(0));
    final topY = tester.getTopLeft(find.text(top.label).first).dy;
    final secondY = tester
        .getTopLeft(find.text(detail.products[1].label).first)
        .dy;
    expect(topY, lessThan(secondY));
  });

  testWidgets('view pipeline button applies unit filter', (tester) async {
    final router = await pumpApp(
      tester,
      dataset,
      initialLocation: '/units/lawyer',
    );
    await tester.scrollUntilVisible(
      find.text('View Lawyer pipeline'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('View Lawyer pipeline'));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/pipeline');
    expect(find.byType(PipelineScreen), findsOneWidget);
    final filter = ProviderScope.containerOf(
      tester.element(find.byType(PipelineScreen)),
    ).read(reportingFilterProvider);
    expect(filter.unitId, 'lawyer');
  });

  testWidgets('unknown unit shows not found', (tester) async {
    await pumpApp(tester, dataset, initialLocation: '/units/nope');
    expect(find.text('Unit not found'), findsOneWidget);
  });

  test('UnitDetail type is exported', () {
    expect(const UnitMetricsCalculator(), isA<UnitMetricsCalculator>());
  });
}
