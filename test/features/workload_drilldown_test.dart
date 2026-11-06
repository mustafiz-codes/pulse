import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app/theme/app_theme.dart';
import 'package:pulse/app/widgets/layout.dart';
import 'package:pulse/core/data/providers.dart';
import 'package:pulse/core/analytics/workload_metrics.dart';
import 'package:pulse/core/models/enums.dart';
import 'package:pulse/core/models/sales_dataset.dart';
import 'package:pulse/features/pipeline/deal_detail_screen.dart';
import 'package:pulse/features/workload/widgets/category_activities_sheet.dart';
import 'package:pulse/features/workload/workload_screen.dart';
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

  Future<void> openOperationsSheet(WidgetTester tester) async {
    final legend = find.descendant(
      of: find.byType(ShareLegend),
      matching: find.text('Operations'),
    );
    for (var i = 0; i < 6 && legend.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(legend.first);
    await tester.pumpAndSettle();
    await tester.tap(legend.first);
    await tester.pumpAndSettle();
  }

  testWidgets('tapping the Operations legend opens its activities', (
    tester,
  ) async {
    await pumpApp(tester, dataset, initialLocation: '/workload');
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WorkloadScreen)),
    );
    final expected = activitiesForCategory(
      container.read(analyticsBundleProvider).scope,
      WorkCategory.operations,
    );
    expect(expected, isNotEmpty);

    await openOperationsSheet(tester);

    expect(
      find.text('Operations activities · ${expected.length}'),
      findsOneWidget,
    );
    expect(find.text('0 min'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an activity row with a deal opens that deal', (tester) async {
    await pumpApp(tester, dataset, initialLocation: '/workload');
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WorkloadScreen)),
    );
    final withDeal = activitiesForCategory(
      container.read(analyticsBundleProvider).scope,
      WorkCategory.operations,
    ).firstWhere((a) => a.dealId != null);

    await openOperationsSheet(tester);
    final row = find.byKey(ValueKey('activity-row-${withDeal.id}'));
    await tester.scrollUntilVisible(
      row,
      200,
      scrollable: find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();

    final detail = tester.widget<DealDetailScreen>(
      find.byType(DealDetailScreen),
    );
    expect(detail.dealId, withDeal.dealId);
  });

  testWidgets('missing durations read Not recorded', (tester) async {
    final missing = dataset.activities.firstWhere(
      (a) => a.durationMinutes == null && a.workCategory == WorkCategory.sales,
    );
    await _pumpSheet(tester, dataset, WorkCategory.sales, [missing]);

    expect(find.text('Not recorded'), findsOneWidget);
    expect(find.text('0 min'), findsNothing);
  });

  testWidgets('sheet says estimated and missing durations are not counted', (
    tester,
  ) async {
    await _pumpSheet(tester, dataset, WorkCategory.sales, const []);

    expect(
      find.textContaining(
        'Estimated and missing durations are listed but not counted',
      ),
      findsOneWidget,
    );
  });

  testWidgets('empty category shows an empty state', (tester) async {
    await _pumpSheet(tester, dataset, WorkCategory.operations, const []);

    expect(find.text('No operations activities logged'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ShareLegend shows a dash, not 0%, with no logged time', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: ShareLegend(
            segments: [
              ShareSegment(label: 'Sales', value: 0, color: Colors.green),
            ],
          ),
        ),
      ),
    );

    expect(find.text('0%'), findsNothing);
    expect(find.text('—'), findsOneWidget);
  });
}

Future<void> _pumpSheet(
  WidgetTester tester,
  SalesDataset dataset,
  WorkCategory category,
  List activities,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showCategoryActivitiesSheet(
              context,
              category: category,
              activities: activities.cast(),
              dataset: dataset,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
