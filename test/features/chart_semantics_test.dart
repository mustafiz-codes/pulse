import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app/theme/app_theme.dart';
import 'package:pulse/app/widgets/people.dart';
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

  Future<void> scrollUntil(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 12 && finder.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('overview booked chart and target ring have text labels', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, dataset);

    expect(find.bySemanticsLabel(RegExp(r'\d% of target')), findsWidgets);

    final chart = find.bySemanticsLabel(
      RegExp(r'^Booked sales chart, \d+ points, latest £'),
    );
    await scrollUntil(tester, chart);
    expect(chart, findsOneWidget);
    handle.dispose();
  });

  testWidgets('overview workload split reads as logged-time shares', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, dataset);

    final bar = find.bySemanticsLabel(
      RegExp(r'^Sales \d+%, Operations \d+%, Other \d+% of logged time$'),
    );
    await scrollUntil(tester, bar);
    expect(bar, findsWidgets);
    handle.dispose();
  });

  testWidgets('workload trend chart has a text summary', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, dataset, initialLocation: '/workload');

    final chart = find.bySemanticsLabel(
      RegExp(r'^Logged time trend, \d+ periods, latest sales '),
    );
    await scrollUntil(tester, chart);
    expect(chart, findsOneWidget);
    handle.dispose();
  });

  testWidgets('ring without a value reads Target unavailable', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: ProgressRing(value: null, size: 60)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Target unavailable'), findsOneWidget);
    handle.dispose();
  });
}
