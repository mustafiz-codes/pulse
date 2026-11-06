import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app/theme/app_colors.dart';
import 'package:pulse/app/theme/app_theme.dart';
import 'package:pulse/app/widgets/app_card.dart';
import 'package:pulse/app/widgets/background.dart';
import 'package:pulse/core/models/sales_dataset.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../support/demo_dataset.dart';
import '../../support/pump_app.dart';

void main() {
  late SalesDataset dataset;

  setUpAll(() async {
    tz.initializeTimeZones();
    dataset = await loadDemoDataset();
  });

  testWidgets('app starts in light theme', (tester) async {
    await pumpApp(tester, dataset);
    final context = tester.element(find.byType(AppCard).first);
    expect(Theme.of(context).brightness, Brightness.light);
    expect(context.pulse.background, const Color(0xFFF4F5F7));
    expect(context.pulse.accent, const Color(0xFF2F6FEB));
    expect(context.pulse.textPrimary, const Color(0xFF0F172A));
  });

  testWidgets('light AppCard has no border and a shadow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: AppCard(child: Text('card'))),
      ),
    );
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(AppCard),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = box.decoration as BoxDecoration;
    expect(decoration.border, isNull);
    expect(decoration.boxShadow, isNotEmpty);
  });

  test('palette exposes 5 unit colours and 6 avatar colours', () {
    for (final palette in [PulsePalette.light, PulsePalette.dark]) {
      expect(palette.unitColors, hasLength(5));
      expect(palette.avatarColors, hasLength(6));
      expect(palette.unitColors.toSet(), hasLength(5));
    }
  });

  testWidgets('overview shows hero wash, pipeline does not', (tester) async {
    await pumpApp(tester, dataset);
    expect(
      tester.widget<PulseBackground>(find.byType(PulseBackground)).heroWash,
      isTrue,
    );
    await tester.tap(find.text('Pipeline').last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<PulseBackground>(find.byType(PulseBackground)).heroWash,
      isFalse,
    );
  });
}
