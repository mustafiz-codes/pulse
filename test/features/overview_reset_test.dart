import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/analytics/reporting_filter.dart';
import 'package:pulse/core/models/sales_dataset.dart';
import 'package:pulse/features/overview/overview_screen.dart';
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

  testWidgets('pull-to-reset restores the default filter', (tester) async {
    await pumpApp(tester, dataset);
    await tester.tap(find.bySemanticsLabel('Last 30 days').first);
    await tester.pumpAndSettle();
    expect(find.text('Last 30 days'), findsWidgets);

    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(OverviewScreen)),
    );
    expect(container.read(reportingFilterProvider), const ReportingFilter());
    expect(find.text('Oct 2026'), findsWidgets);
    expect(find.byType(SnackBar), findsNothing);
  });
}
