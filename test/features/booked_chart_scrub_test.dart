import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/models/sales_dataset.dart';
import 'package:pulse/features/overview/widgets/booked_target_chart.dart';
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

  testWidgets('touch-and-hold scrub across the booked chart is clean', (
    tester,
  ) async {
    await pumpApp(tester, dataset);
    final chart = find.byType(BookedTargetChart);
    for (var i = 0; i < 10 && chart.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(chart);
    await tester.pumpAndSettle();

    final rect = tester.getRect(
      find.descendant(of: chart, matching: find.byType(LineChart)),
    );
    final gesture = await tester.startGesture(
      Offset(rect.left + 60, rect.center.dy),
    );
    await tester.pump();
    for (var dx = 0; dx < 240; dx += 6) {
      await gesture.moveBy(const Offset(6, 0));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'scrub +$dx px');
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
