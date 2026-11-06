import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/models/sales_dataset.dart';
import 'package:pulse/features/conversion/conversion_screen.dart';
import 'package:pulse/features/pipeline/pipeline_screen.dart';
import 'package:pulse/features/team/team_screen.dart';
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

  final cases = <String, Type>{
    'Win rate': PipelineScreen,
    'Median lead-to-win': ConversionScreen,
    'Open pipeline': PipelineScreen,
    'Target attainment': TeamScreen,
  };

  for (final entry in cases.entries) {
    testWidgets('tapping ${entry.key} opens ${entry.value}', (tester) async {
      await pumpApp(tester, dataset);
      final card = find.text(entry.key);
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();

      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(find.byType(entry.value), findsOneWidget);
    });
  }
}
