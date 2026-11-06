import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app/theme/app_theme.dart';
import 'package:pulse/app/widgets/people.dart';
import 'package:pulse/app/widgets/unit_tag.dart';
import 'package:pulse/app/widgets/user_avatar.dart';
import 'package:pulse/core/data/providers.dart';
import 'package:pulse/core/models/sales_dataset.dart';

import '../../support/demo_dataset.dart';
import '../../support/fonts.dart';

void main() {
  late SalesDataset dataset;

  setUpAll(() async {
    await loadInterFonts();
    dataset = await loadDemoDataset();
  });

  Future<void> pump(WidgetTester tester, Widget child, {double width = 400}) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [salesDatasetProvider.overrideWithValue(dataset)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('product tag shows product and unit', (tester) async {
    await pump(tester, const UnitTag(productId: 'skilled_worker'));
    expect(find.text('Skilled Worker Sponsorship · Global'), findsOneWidget);
  });

  testWidgets('unit-only tag shows unit label', (tester) async {
    await pump(tester, const UnitTag(unitId: 'hr'));
    expect(find.text('HR'), findsOneWidget);
  });

  testWidgets('long tag ellipsizes at 200px with full semantics label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      const Align(
        alignment: Alignment.centerLeft,
        child: UnitTag(productId: 'skilled_worker'),
      ),
      width: 200,
    );
    expect(tester.takeException(), isNull);
    expect(
      find.bySemanticsLabel('Skilled Worker Sponsorship · Global'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('user avatar colour is stable', (tester) async {
    await pump(
      tester,
      const Row(
        children: [
          UserAvatar(userId: 'rep_02', key: ValueKey('a')),
          UserAvatar(userId: 'rep_02', key: ValueKey('b')),
          UserAvatar(userId: 'rep_03', key: ValueKey('c')),
        ],
      ),
    );
    Color colorOf(String key) => tester
        .widget<InitialsAvatar>(
          find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(InitialsAvatar),
          ),
        )
        .color!;
    expect(colorOf('a'), colorOf('b'));
    expect(colorOf('a'), isNot(colorOf('c')));
    expect(find.text('M'), findsNWidgets(2));
  });
}
