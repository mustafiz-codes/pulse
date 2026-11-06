import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/analytics/reporting_filter.dart';
import 'package:pulse/core/models/sales_dataset.dart';
import 'package:pulse/features/workload/workload_screen.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../support/demo_dataset.dart';
import '../support/pump_app.dart';

void main() {
  late SalesDataset dataset;

  setUpAll(() async {
    tz.initializeTimeZones();
    dataset = await loadDemoDataset();
  });

  testWidgets('workload explains excluded internal time under a unit filter', (
    tester,
  ) async {
    await pumpApp(tester, dataset, initialLocation: '/workload');
    const note = 'Internal time not assigned to a unit is excluded.';
    expect(find.textContaining(note), findsNothing);

    ProviderScope.containerOf(
      tester.element(find.byType(WorkloadScreen)),
    ).read(reportingFilterProvider.notifier).setUnit('hr');
    await tester.pumpAndSettle();
    expect(find.textContaining(note), findsOneWidget);
  });
}
