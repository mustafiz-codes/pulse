import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app/widgets/filter_bar.dart';
import 'package:pulse/app/widgets/top_bar.dart';
import 'package:pulse/core/models/sales_dataset.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../support/demo_dataset.dart';
import '../../support/fonts.dart';
import '../../support/pump_app.dart';

void main() {
  late SalesDataset dataset;

  setUpAll(() async {
    tz.initializeTimeZones();
    await loadInterFonts();
    dataset = await loadDemoDataset();
  });

  testWidgets('header is a single row under 64 px', (tester) async {
    await pumpApp(tester, dataset);
    expect(tester.getSize(find.byType(PulseTopBar)).height, lessThan(64));
    expect(find.textContaining('As of'), findsNothing);
  });

  testWidgets('segmented switch fits one line at 360x740 x1.3', (tester) async {
    await pumpApp(tester, dataset, size: const Size(360, 740), textScale: 1.3);
    expect(tester.takeException(), isNull);
    final control = find.byType(PeriodSegmentedControl).first;
    final ys = [
      for (final label in ['7D', '30D', 'Month', 'Quarter'])
        tester
            .getCenter(find.descendant(of: control, matching: find.text(label)))
            .dy,
    ];
    expect(ys.toSet(), hasLength(1));
  });

  testWidgets('period button opens sheet with as-of line and filters', (
    tester,
  ) async {
    await pumpApp(tester, dataset);
    expect(
      find.descendant(
        of: find.byType(PeriodButton),
        matching: find.text('Oct 2026'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Period and filters'));
    await tester.pumpAndSettle();
    expect(find.textContaining('As of 31 Oct 2026'), findsOneWidget);
    expect(find.text('Custom range'), findsOneWidget);
    expect(find.text('REP'), findsOneWidget);
    expect(find.text('SOURCE'), findsOneWidget);
    expect(find.text('STAGE'), findsOneWidget);
  });

  testWidgets('overflow menu holds scenarios, reset, theme', (tester) async {
    await pumpApp(tester, dataset);
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    expect(find.text('Presentation scenarios'), findsOneWidget);
    expect(find.text('Reset demo'), findsOneWidget);
    expect(find.text('Dark theme'), findsOneWidget);
    await tester.tap(find.text('Dark theme'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(PulseTopBar))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('30D segment switches window', (tester) async {
    await pumpApp(tester, dataset);
    await tester.tap(find.bySemanticsLabel('Last 30 days').first);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(PeriodButton),
        matching: find.text('Last 30 days'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('short titles', (tester) async {
    final router = await pumpApp(tester, dataset);
    expect(find.text('Executive overview'), findsOneWidget);
    router.go('/pipeline');
    await tester.pumpAndSettle();
    expect(find.text('Sales pipeline'), findsOneWidget);
    router.go('/team');
    await tester.pumpAndSettle();
    expect(find.text('Team performance'), findsOneWidget);
    router.go('/leads');
    await tester.pumpAndSettle();
    expect(find.text('Lead intelligence'), findsOneWidget);
  });
}
