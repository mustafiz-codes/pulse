import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/models/sales_dataset.dart';
import 'package:pulse/core/utils/labels.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../support/demo_dataset.dart';
import '../support/fonts.dart';
import '../support/pump_app.dart';

Finder _leadRows() => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key as ValueKey<String>).value.startsWith('lead-row-'),
);

String _leadId(WidgetTester tester, Finder row) =>
    (tester.widget(row).key as ValueKey<String>).value.substring(
      'lead-row-'.length,
    );

Finder _inSheet(Finder finder) =>
    find.descendant(of: find.byType(BottomSheet), matching: finder);

void main() {
  late SalesDataset dataset;

  setUpAll(() async {
    tz.initializeTimeZones();
    await loadInterFonts();
    dataset = await loadDemoDataset();
  });

  Future<Finder> firstRow(WidgetTester tester) async {
    await pumpApp(tester, dataset, initialLocation: '/leads');
    for (var i = 0; i < 8 && _leadRows().evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    final row = _leadRows().first;
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    return row;
  }

  void expectPreviewFor(WidgetTester tester, String leadId) {
    final lead = dataset.leadsById[leadId]!;
    final account = dataset.accountsById[lead.accountId]!;
    final owner = dataset.usersById[lead.ownerId]!;
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(_inSheet(find.text(account.name)), findsOneWidget);
    expect(_inSheet(find.textContaining(lead.source.label)), findsWidgets);
    expect(_inSheet(find.textContaining(owner.displayName)), findsWidgets);
    expect(_inSheet(find.text('First response')), findsOneWidget);
    expect(_inSheet(find.text('Open lead')), findsOneWidget);
    expect(_inSheet(find.byIcon(Icons.call_outlined)), findsNothing);
    expect(_inSheet(find.byIcon(Icons.email_outlined)), findsNothing);
  }

  testWidgets('swipe opens a read-only preview and keeps the row', (
    tester,
  ) async {
    final row = await firstRow(tester);
    final id = _leadId(tester, row);

    await tester.drag(row, const Offset(-260, 0));
    await tester.pumpAndSettle();

    expectPreviewFor(tester, id);

    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('lead-row-$id')), findsWidgets);
  });

  testWidgets('long-press opens the same preview', (tester) async {
    final row = await firstRow(tester);
    final id = _leadId(tester, row);

    await tester.longPress(row);
    await tester.pumpAndSettle();

    expectPreviewFor(tester, id);
  });

  testWidgets('Open lead in the preview navigates to lead detail', (
    tester,
  ) async {
    final row = await firstRow(tester);
    await tester.longPress(row);
    await tester.pumpAndSettle();

    await tester.tap(_inSheet(find.text('Open lead')));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byTooltip('Back'), findsOneWidget);
  });
}
