import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app/widgets/animated_reorder_column.dart';
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

  testWidgets('ranking mode change glides rep rows to new slots', (
    tester,
  ) async {
    await pumpApp(tester, dataset, initialLocation: '/team');
    final column = find.byType(AnimatedReorderColumn);
    for (var i = 0; i < 10 && column.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    expect(column, findsOneWidget);
    await tester.ensureVisible(column);
    await tester.pumpAndSettle();

    final names = [
      for (final u in dataset.activeUsers)
        if (find
            .descendant(of: column, matching: find.text(u.displayName))
            .evaluate()
            .isNotEmpty)
          u.displayName,
    ];
    double top(String name) => tester
        .getTopLeft(find.descendant(of: column, matching: find.text(name)))
        .dy;
    await tester.ensureVisible(find.text('Win rate'));
    await tester.pumpAndSettle();
    final before = {for (final n in names) n: top(n)};
    await tester.tap(find.text('Win rate'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final mid = {for (final n in names) n: top(n)};
    await tester.pumpAndSettle();
    final after = {for (final n in names) n: top(n)};

    final moved = names
        .where((n) => (before[n]! - after[n]!).abs() > 2)
        .toList();
    expect(moved, isNotEmpty, reason: 'win-rate order differs from booked');
    for (final n in moved) {
      final lo = before[n]! < after[n]! ? before[n]! : after[n]!;
      final hi = before[n]! < after[n]! ? after[n]! : before[n]!;
      expect(
        mid[n]! > lo && mid[n]! < hi,
        isTrue,
        reason:
            '$n mid-flight before=${before[n]} mid=${mid[n]} after=${after[n]}',
      );
    }
    expect(tester.takeException(), isNull);
  });
}
