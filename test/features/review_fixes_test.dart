import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app/shell/pulse_shell.dart';
import 'package:pulse/core/analytics/analytics_bundle.dart';
import 'package:pulse/core/analytics/reporting_filter.dart';
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

  testWidgets('period sheet scrolls and keeps Show results reachable at x1.3', (
    tester,
  ) async {
    await pumpApp(tester, dataset, size: const Size(360, 740), textScale: 1.3);
    await tester.tap(find.byTooltip('Period and filters'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final button = find.text('Show results');
    expect(button, findsOneWidget);
    final rect = tester.getRect(button);
    expect(rect.bottom, lessThanOrEqualTo(740));
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(button, findsNothing);
  });

  test('booked-vs-target chart has no target under a unit filter', () {
    final bundle = AnalyticsBundle.compute(
      dataset: dataset,
      filter: const ReportingFilter(unitId: 'lawyer'),
    );
    expect(bundle.monthlySeries, isNotEmpty);
    expect(bundle.monthlySeries.every((p) => p.targetMinor == null), isTrue);
    final all = AnalyticsBundle.compute(
      dataset: dataset,
      filter: const ReportingFilter(),
    );
    expect(all.monthlySeries.any((p) => p.targetMinor != null), isTrue);
  });

  for (final dark in [false, true]) {
    testWidgets(
      'tab shell sets system bar style (${dark ? 'dark' : 'light'})',
      (tester) async {
        await pumpApp(tester, dataset);
        if (dark) await tapMenuItem(tester, 'Dark theme');
        final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find
              .descendant(
                of: find.byType(PulseShell),
                matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
              )
              .first,
        );
        expect(
          region.value.statusBarIconBrightness,
          dark ? Brightness.light : Brightness.dark,
        );
        expect(region.value.systemNavigationBarColor, isNotNull);
        expect(
          region.value.systemNavigationBarIconBrightness,
          dark ? Brightness.light : Brightness.dark,
        );
      },
    );
  }
}
