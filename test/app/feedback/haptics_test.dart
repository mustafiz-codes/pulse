import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/models/sales_dataset.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../support/demo_dataset.dart';
import '../../support/fonts.dart';
import '../../support/pump_app.dart';

const _selectionClick = 'HapticFeedbackType.selectionClick';
const _lightImpact = 'HapticFeedbackType.lightImpact';

void main() {
  late SalesDataset dataset;

  setUpAll(() async {
    tz.initializeTimeZones();
    await loadInterFonts();
    dataset = await loadDemoDataset();
  });

  List<Object?> recordHaptics(WidgetTester tester) {
    final calls = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') calls.add(call.arguments);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    return calls;
  }

  testWidgets('period chip tap emits a selection click', (tester) async {
    await pumpApp(tester, dataset);
    final calls = recordHaptics(tester);

    await tester.tap(find.bySemanticsLabel('Last 30 days').first);
    await tester.pumpAndSettle();

    expect(calls, contains(_selectionClick));
  });

  testWidgets('tab change emits a selection click', (tester) async {
    await pumpApp(tester, dataset);
    final calls = recordHaptics(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Leads'),
      ),
    );
    await tester.pumpAndSettle();

    expect(calls, contains(_selectionClick));
  });

  testWidgets('Reset demo emits a light impact', (tester) async {
    await pumpApp(tester, dataset);
    final calls = recordHaptics(tester);

    await tapMenuItem(tester, 'Reset demo');

    expect(calls, contains(_lightImpact));
  });
}
