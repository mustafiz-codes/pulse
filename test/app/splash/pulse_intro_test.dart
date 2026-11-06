import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app/pulse_app.dart';
import 'package:pulse/app/splash/intro_controller.dart';
import 'package:pulse/app/splash/pulse_intro.dart';
import 'package:pulse/core/models/sales_dataset.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../support/demo_dataset.dart';
import '../../support/pump_app.dart';

const _intro = ValueKey('pulse-intro');
const _introLogo = ValueKey('pulse-intro-logo');

void main() {
  late SalesDataset dataset;

  setUpAll(() async {
    tz.initializeTimeZones();
    dataset = await loadDemoDataset();
  });

  IntroPhase phase(WidgetTester tester) => ProviderScope.containerOf(
    tester.element(find.byType(PulseApp)),
  ).read(introPhaseProvider);

  double headerLogoOpacity(WidgetTester tester) => tester
      .widget<Opacity>(
        find
            .ancestor(
              of: find.byKey(pulseHeaderLogoKey),
              matching: find.byType(Opacity),
            )
            .first,
      )
      .opacity;

  testWidgets('intro overlay shows on cold start', (tester) async {
    await pumpApp(tester, dataset, intro: true);
    expect(find.byKey(_intro), findsOneWidget);
    expect(phase(tester), IntroPhase.playing);
  });

  testWidgets('intro finishes after 1.8 s', (tester) async {
    await pumpApp(tester, dataset, intro: true);
    await tester.pump(pulseIntroDuration + const Duration(milliseconds: 50));
    await tester.pump();
    expect(find.byKey(_intro), findsNothing);
    expect(phase(tester), IntroPhase.done);
  });

  testWidgets('header logo hidden during intro, visible after', (tester) async {
    await pumpApp(tester, dataset, intro: true);
    await tester.pump(const Duration(milliseconds: 900));
    expect(headerLogoOpacity(tester), 0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(headerLogoOpacity(tester), 1);
  });

  testWidgets('logo lands on header logo position', (tester) async {
    await pumpApp(tester, dataset, intro: true);
    await tester.pump(const Duration(milliseconds: 1782));
    final flying = tester.getRect(find.byKey(_introLogo));
    final target = tester.getRect(find.byKey(pulseHeaderLogoKey));
    expect((flying.left - target.left).abs(), lessThan(2));
    expect((flying.top - target.top).abs(), lessThan(2));
    expect((flying.width - target.width).abs(), lessThan(2));
  });

  testWidgets('tap skips intro', (tester) async {
    await pumpApp(tester, dataset, intro: true);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(_intro));
    await tester.pump();
    expect(find.byKey(_intro), findsNothing);
    expect(headerLogoOpacity(tester), 1);
  });

  testWidgets('reduce motion skips intro', (tester) async {
    await pumpApp(tester, dataset, intro: true, disableAnimations: true);
    await tester.pump();
    expect(find.byKey(_intro), findsNothing);
    expect(phase(tester), IntroPhase.done);
  });

  testWidgets('intro_does_not_replay', (tester) async {
    await pumpApp(tester, dataset, intro: true);
    await tester.pump(pulseIntroDuration + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pipeline').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Overview').last);
    await tester.pump();
    expect(find.byKey(_intro), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(_intro), findsNothing);
  });

  testWidgets('intro_without_header_fades', (tester) async {
    await pumpApp(
      tester,
      dataset,
      initialLocation: '/deals/deal_0031',
      intro: true,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(_intro), findsNothing);
  });

  testWidgets('intro disabled by default in tests', (tester) async {
    await pumpApp(tester, dataset);
    expect(find.byKey(_intro), findsNothing);
    expect(headerLogoOpacity(tester), 1);
  });
}
