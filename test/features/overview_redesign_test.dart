import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app/widgets/section.dart';
import 'package:pulse/app/widgets/user_avatar.dart';
import 'package:pulse/core/analytics/metric_definitions.dart';
import 'package:pulse/core/analytics/reporting_filter.dart';
import 'package:pulse/core/analytics/team_metrics.dart';
import 'package:pulse/core/data/providers.dart';
import 'package:pulse/core/models/sales_dataset.dart';
import 'package:pulse/features/overview/overview_screen.dart';
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

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(OverviewScreen)));

  testWidgets('hero card shows booked value with won pill and target bar', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, dataset);
    expect(find.byKey(const ValueKey('overview-hero')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('overview-hero')),
        matching: find.textContaining('won deals'),
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp(r'of target$')), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('overview-hero')),
        matching: find.byType(LinearProgressIndicator),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('unit filter replaces target bar with No unit targets', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, dataset);
    container(tester).read(reportingFilterProvider.notifier).setUnit('lawyer');
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('No unit targets'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('KPI strip scrolls horizontally and keeps drill-throughs', (
    tester,
  ) async {
    await pumpApp(tester, dataset, size: const Size(360, 800));
    final strip = find.byKey(const ValueKey('overview-kpi-strip'));
    expect(strip, findsOneWidget);
    await tester.drag(strip, const Offset(-400, 0));
    await tester.pumpAndSettle();
    final stalled = find.descendant(of: strip, matching: find.text('Stalled'));
    expect(stalled, findsOneWidget);
    await tester.drag(strip, const Offset(600, 0));
    await tester.pumpAndSettle();
    final open = find.descendant(
      of: strip,
      matching: find.text('Open pipeline'),
    );
    await tester.ensureVisible(open);
    await tester.pumpAndSettle();
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(find.byType(PipelineScreen), findsOneWidget);
  });

  testWidgets('top performers lists 3 reps with avatars and unit tags', (
    tester,
  ) async {
    await pumpApp(tester, dataset);
    final card = find.byKey(const ValueKey('overview-top-performers'));
    await tester.ensureVisible(card);
    expect(
      find.descendant(of: card, matching: find.byType(UserAvatar)),
      findsNWidgets(3),
    );
    final bundle = container(tester).read(analyticsBundleProvider);
    final leader = bundle.team
        .ranked(RankingMode.bookedSales)
        .first
        .user
        .displayName;
    expect(
      find.descendant(of: card, matching: find.text(leader)),
      findsOneWidget,
    );
  });

  testWidgets('by unit shows all 5 units and opens unit detail', (
    tester,
  ) async {
    await pumpApp(tester, dataset);
    final card = find.byKey(const ValueKey('overview-by-unit'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    for (final label in ['Lawyer', 'Cloud', 'HR', 'Accountant', 'Global']) {
      expect(
        find.descendant(of: card, matching: find.text(label)),
        findsOneWidget,
      );
    }
    await tester.tap(find.descendant(of: card, matching: find.text('Lawyer')));
    await tester.pumpAndSettle();
    expect(find.byType(UnitDetailScreen), findsOneWidget);
  });

  testWidgets('every KPI card info key has a definition', (tester) async {
    await pumpApp(tester, dataset);
    final keys = tester
        .widgetList<KpiCard>(find.byType(KpiCard))
        .map((card) => card.metricKey)
        .whereType<String>()
        .toList();
    expect(keys, isNotEmpty);
    for (final key in keys) {
      expect(metricDefinitions.containsKey(key), isTrue, reason: key);
    }
  });
}
