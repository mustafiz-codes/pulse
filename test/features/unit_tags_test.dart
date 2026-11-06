import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app/widgets/unit_tag.dart';
import 'package:pulse/app/widgets/user_avatar.dart';
import 'package:pulse/core/analytics/reporting_filter.dart';
import 'package:pulse/core/models/sales_dataset.dart';
import 'package:pulse/features/pipeline/pipeline_screen.dart';
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

  Iterable<String> tagTexts(WidgetTester tester) =>
      tester.widgetList<UnitTag>(find.byType(UnitTag)).map((tag) {
        final unitId = tag.unitId ?? dataset.unitIdOf(tag.productId!);
        return dataset.unitFor(unitId).label;
      });

  testWidgets('deal cards carry unit tags and owner avatars', (tester) async {
    await pumpApp(tester, dataset, initialLocation: '/pipeline');
    await tester.scrollUntilVisible(
      find.byType(UnitTag).first,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(UnitTag), findsWidgets);
    expect(find.byType(UserAvatar), findsWidgets);
  });

  testWidgets('lead rows carry unit tags', (tester) async {
    await pumpApp(tester, dataset, initialLocation: '/leads');
    await tester.scrollUntilVisible(
      find.byType(UnitTag).first,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(UnitTag), findsWidgets);
  });

  testWidgets('pipeline filtered to lawyer shows only lawyer tags', (
    tester,
  ) async {
    await pumpApp(tester, dataset, initialLocation: '/pipeline');
    ProviderScope.containerOf(
      tester.element(find.byType(PipelineScreen)),
    ).read(reportingFilterProvider.notifier).setUnit('lawyer');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(UnitTag).first,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tagTexts(tester), isNotEmpty);
    expect(tagTexts(tester).toSet(), {'Lawyer'});
  });

  testWidgets('team tab has no Team comparison section, rows have avatars', (
    tester,
  ) async {
    await pumpApp(tester, dataset, initialLocation: '/team');
    expect(find.text('Team comparison'), findsNothing);
    await tester.scrollUntilVisible(
      find.byType(UserAvatar).first,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(UserAvatar), findsWidgets);
    expect(find.byType(UnitTag), findsWidgets);
  });

  testWidgets('deal, lead and rep detail headers show tags', (tester) async {
    final deal = dataset.deals.first;
    final router = await pumpApp(tester, dataset, initialLocation: '/pipeline');
    router.push('/deals/${deal.id}');
    await tester.pumpAndSettle();
    expect(find.byType(UnitTag), findsWidgets);
    router.go('/leads');
    await tester.pumpAndSettle();
    router.push('/leads/${dataset.leads.first.id}');
    await tester.pumpAndSettle();
    expect(find.byType(UnitTag), findsWidgets);
    router.go('/team');
    await tester.pumpAndSettle();
    router.push('/team/rep_02');
    await tester.pumpAndSettle();
    expect(find.byType(UserAvatar), findsWidgets);
    expect(find.byType(UnitTag), findsWidgets);
  });
}
