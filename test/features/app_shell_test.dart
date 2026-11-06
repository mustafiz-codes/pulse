import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/models/sales_dataset.dart';
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

  testWidgets('four tabs navigate and keep the demo badge visible', (
    tester,
  ) async {
    await pumpApp(tester, dataset);

    expect(find.text('Executive overview'), findsOneWidget);
    expect(find.text('DEMO DATA'), findsOneWidget);

    final navigation = find.byType(NavigationBar);
    await tester.tap(
      find.descendant(of: navigation, matching: find.text('Leads')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lead intelligence'), findsOneWidget);
    expect(find.text('DEMO DATA'), findsOneWidget);

    await tester.tap(
      find.descendant(of: navigation, matching: find.text('Pipeline')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sales pipeline'), findsOneWidget);
    expect(find.text('DEMO DATA'), findsOneWidget);

    await tester.tap(
      find.descendant(of: navigation, matching: find.text('Team')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Team performance'), findsOneWidget);
    expect(find.text('DEMO DATA'), findsOneWidget);

    expect(
      tester.widget<NavigationBar>(navigation).selectedIndex,
      3,
      reason: 'Team should remain the selected tab',
    );
  });

  testWidgets('period preset updates the reporting window coherently', (
    tester,
  ) async {
    await pumpApp(tester, dataset);

    expect(find.text('Oct 2026'), findsWidgets);

    await tester.tap(find.bySemanticsLabel('Last 30 days').first);
    await tester.pumpAndSettle();

    expect(find.text('Last 30 days'), findsWidgets);
    expect(find.text('Oct 2026'), findsNothing);
  });

  testWidgets('scenario menu applies context, navigates, and resets', (
    tester,
  ) async {
    await pumpApp(tester, dataset);

    await tapMenuItem(tester, 'Presentation scenarios');
    expect(find.text('Presentation scenarios'), findsOneWidget);
    expect(find.text('Conversion bottleneck'), findsOneWidget);

    await tester.tap(find.text('Conversion bottleneck'));
    await tester.pumpAndSettle();

    expect(find.text('Conversion analytics'), findsOneWidget);
    expect(find.text('DEMO DATA'), findsOneWidget);

    await tapMenuItem(tester, 'Reset demo');

    expect(find.text('Executive overview'), findsOneWidget);
    expect(find.text('Oct 2026'), findsWidgets);
  });

  testWidgets('theme toggle switches between dark and light', (tester) async {
    await pumpApp(tester, dataset);

    BuildContext badgeContext() => tester.element(find.text('DEMO DATA'));

    expect(Theme.of(badgeContext()).brightness, Brightness.light);

    await tapMenuItem(tester, 'Dark theme');

    expect(Theme.of(badgeContext()).brightness, Brightness.dark);
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    expect(find.text('Light theme'), findsOneWidget);
    expect(find.text('DEMO DATA'), findsOneWidget);
  });

  testWidgets('deal detail pushes above the tab shell and back restores it', (
    tester,
  ) async {
    final router = await pumpApp(tester, dataset, initialLocation: '/pipeline');
    final deal = dataset.deals.firstWhere((deal) => deal.isOpen);
    final account = dataset.accountsById[deal.accountId]!;

    router.push('/deals/${deal.id}');
    await tester.pumpAndSettle();

    expect(find.text(account.name), findsWidgets);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.text('DEMO DATA'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Sales pipeline'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
      reason: 'Back should return to the pipeline tab',
    );
  });
}
