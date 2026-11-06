import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('detail screens use dark status bar icons in light theme', (
    tester,
  ) async {
    await pumpApp(tester, dataset, initialLocation: '/units/lawyer');
    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find
          .descendant(
            of: find.byType(AppBar),
            matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
          )
          .first,
    );
    expect(region.value.statusBarIconBrightness, Brightness.dark);
    expect(region.value.statusBarBrightness, Brightness.light);
  });

  testWidgets('top performer values share one right edge', (tester) async {
    await pumpApp(tester, dataset);
    final card = find.byKey(const ValueKey('overview-top-performers'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    final values = find.descendant(
      of: card,
      matching: find.textContaining(RegExp(r'^£')),
    );
    final rights = [
      for (final e in values.evaluate())
        tester.getTopRight(find.byWidget(e.widget)).dx,
    ];
    expect(rights, hasLength(3));
    expect(rights.toSet(), hasLength(1), reason: '$rights');
  });

  testWidgets('filter copy says unit, not team', (tester) async {
    await pumpApp(tester, dataset, initialLocation: '/pipeline');
    expect(find.textContaining('team and source'), findsNothing);
    expect(find.textContaining('unit and source'), findsOneWidget);
  });
}
