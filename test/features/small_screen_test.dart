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

  testWidgets('highest-value deal detail fits at 360x740, text x1.3', (
    tester,
  ) async {
    final deal = dataset.deals.reduce(
      (a, b) => a.valueMinor >= b.valueMinor ? a : b,
    );
    await pumpApp(
      tester,
      dataset,
      initialLocation: '/deals/${deal.id}',
      size: const Size(360, 740),
      textScale: 1.3,
    );
    _expectNoException(tester, 'deal ${deal.id}');
  });

  testWidgets('Global unit detail fits at 360x740, text x1.3', (tester) async {
    await pumpApp(
      tester,
      dataset,
      initialLocation: '/units/global',
      size: const Size(360, 740),
      textScale: 1.3,
    );
    _expectNoException(tester, 'units/global');
    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      _expectNoException(tester, 'units/global scroll $i');
    }
  });

  testWidgets('longest product tag deal card fits at 360x740, text x1.3', (
    tester,
  ) async {
    final deal = dataset.deals.firstWhere(
      (d) => d.productId == 'skilled_worker',
      orElse: () => dataset.deals.first,
    );
    await pumpApp(
      tester,
      dataset,
      initialLocation: '/deals/${deal.id}',
      size: const Size(360, 740),
      textScale: 1.3,
    );
    _expectNoException(tester, 'deal ${deal.id} (${deal.productId})');
  });

  testWidgets('lead preview sheet fits at 360x740, text x1.3', (tester) async {
    await pumpApp(
      tester,
      dataset,
      initialLocation: '/leads',
      size: const Size(360, 740),
      textScale: 1.3,
    );
    final rows = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key as ValueKey<String>).value.startsWith('lead-row-'),
    );
    for (var i = 0; i < 10 && rows.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(rows.first);
    await tester.pumpAndSettle();
    await tester.longPress(rows.first);
    await tester.pumpAndSettle();
    _expectNoException(tester, 'lead preview');

    final open = find.text('Open lead');
    await tester.ensureVisible(open);
    await tester.pumpAndSettle();
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('Team rows fit under Android-style non-linear scaling', (
    tester,
  ) async {
    await pumpApp(
      tester,
      dataset,
      initialLocation: '/team',
      size: const Size(360, 740),
      textScaler: const _AndroidLikeScaler(),
    );
    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      _expectNoException(tester, 'team step $i');
    }
  });

  for (final tab in ['Overview', 'Leads', 'Pipeline', 'Team']) {
    testWidgets('$tab renders without overflow at 360x740, text x1.3', (
      tester,
    ) async {
      await pumpApp(
        tester,
        dataset,
        size: const Size(360, 740),
        textScale: 1.3,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      _expectNoException(tester, '$tab initial');

      for (var i = 0; i < 8; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
        await tester.pumpAndSettle();
        _expectNoException(tester, '$tab scroll step $i');
      }
    });
  }
}

/// Approximates Android 14+ non-linear font scaling at the "1.3" step:
/// small text grows ~1.3x, large text barely grows.
class _AndroidLikeScaler extends TextScaler {
  const _AndroidLikeScaler();

  @override
  double scale(double fontSize) {
    final t = ((fontSize - 12) / 18).clamp(0.0, 1.0);
    return fontSize * (1.3 - 0.3 * t);
  }

  @override
  double get textScaleFactor => 1.3;

  @override
  TextScaler clamp({
    double minScaleFactor = 0,
    double maxScaleFactor = double.infinity,
  }) => this;

  @override
  bool operator ==(Object other) => other is _AndroidLikeScaler;

  @override
  int get hashCode => 13;
}

void _expectNoException(WidgetTester tester, String where) {
  final error = tester.takeException();
  expect(
    error,
    isNull,
    reason: '$where: ${error is FlutterError ? error.toStringDeep() : error}',
  );
}
