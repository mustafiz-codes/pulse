import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app/bootstrap.dart';
import 'package:pulse/app/router.dart';
import 'package:pulse/core/models/sales_dataset.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../support/demo_dataset.dart';
import '../support/fonts.dart';

/// Any attempt to open an HTTP connection fails the test loudly.
class _NoNetwork extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw StateError('Network access attempted');
}

void main() {
  late SalesDataset dataset;
  HttpOverrides? previous;

  setUpAll(() async {
    tz.initializeTimeZones();
    await loadInterFonts();
    dataset = await loadDemoDataset();
  });

  setUp(() {
    previous = HttpOverrides.current;
    HttpOverrides.global = _NoNetwork();
  });

  tearDown(() => HttpOverrides.global = previous);

  test('the guard is live: creating an HttpClient throws', () {
    expect(HttpClient.new, throwsStateError);
  });

  testWidgets('real bundled data boots and renders every route offline', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PulseBootstrap());
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      if (find.text('Executive overview').evaluate().isNotEmpty) break;
    }
    expect(find.text('Executive overview'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final routes = [
      '/leads',
      '/pipeline',
      '/team',
      '/overview',
      '/conversion',
      '/workload',
      '/deals/deal_0013',
      '/leads/${dataset.leads.first.id}',
      '/team/${dataset.activeUsers.first.id}',
    ];
    for (final route in routes) {
      appRouter.go(route);
      await tester.pumpAndSettle();
      expect(find.text('DEMO DATA'), findsWidgets, reason: route);
      expect(tester.takeException(), isNull, reason: route);
    }
    appRouter.go('/overview');
    await tester.pumpAndSettle();
  });
}
