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

  const sizes = {'landscape': Size(1200, 800), 'portrait': Size(800, 1280)};

  testWidgets('tablet: conversion and workload cards sit side by side', (
    tester,
  ) async {
    await pumpApp(tester, dataset, size: const Size(1200, 800));
    final conversion = find.text('Conversion bottleneck');
    final workload = find.text('Sales vs operations');
    for (var i = 0; i < 10 && conversion.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(conversion.first);
    await tester.pumpAndSettle();
    final a = tester.getTopLeft(conversion.first);
    final b = tester.getTopLeft(workload.first);
    expect((a.dy - b.dy).abs(), lessThan(40));
    expect(b.dx, greaterThan(a.dx + 200));
  });

  for (final entry in sizes.entries) {
    testWidgets('${entry.key}: hero card is capped at 720 px', (tester) async {
      await pumpApp(tester, dataset, size: entry.value);
      final hero = tester.getSize(find.byKey(const ValueKey('overview-hero')));
      expect(hero.width, lessThanOrEqualTo(720));
    });

    testWidgets('${entry.key}: navigation bar spans the full width', (
      tester,
    ) async {
      await pumpApp(tester, dataset, size: entry.value);
      expect(
        tester.getSize(find.byType(NavigationBar)).width,
        entry.value.width,
      );
    });

    for (final route in [
      '/overview',
      '/leads',
      '/pipeline',
      '/team',
      '/units/lawyer',
      '/workload',
    ]) {
      testWidgets('${entry.key}: $route renders without overflow', (
        tester,
      ) async {
        await pumpApp(
          tester,
          dataset,
          initialLocation: route,
          size: entry.value,
        );
        expect(tester.takeException(), isNull);
        final content = tester.getSize(find.byType(Scrollable).first);
        expect(content.width, lessThanOrEqualTo(720), reason: route);
      });
    }
  }
}
