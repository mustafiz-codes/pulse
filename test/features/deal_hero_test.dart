import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse/app/widgets/hero_tags.dart';
import 'package:pulse/core/data/providers.dart';
import 'package:pulse/core/models/sales_dataset.dart';
import 'package:pulse/features/pipeline/deal_detail_screen.dart';
import 'package:pulse/features/pipeline/pipeline_screen.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../support/demo_dataset.dart';
import '../support/fonts.dart';
import '../support/pump_app.dart';

const _pipelineTitle = 'Sales pipeline';

Finder _dealHeroes() => find.byWidgetPredicate(
  (w) => w is Hero && w.tag is String && (w.tag as String).startsWith('deal-'),
);

Future<void> _scrollToFirstDeal(WidgetTester tester) async {
  for (var i = 0; i < 20 && _dealHeroes().evaluate().isEmpty; i++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
  }
  expect(_dealHeroes(), findsWidgets);
  await tester.ensureVisible(_dealHeroes().first);
  await tester.pumpAndSettle();
}

void main() {
  late SalesDataset dataset;

  setUpAll(() async {
    tz.initializeTimeZones();
    await loadInterFonts();
    dataset = await loadDemoDataset();
  });

  testWidgets('deal card and detail header share a Hero tag', (tester) async {
    await pumpApp(tester, dataset, initialLocation: '/pipeline');
    await _scrollToFirstDeal(tester);

    expect(_dealHeroes(), findsWidgets);
    final tag = tester.widget<Hero>(_dealHeroes().first).tag as String;
    final cardHero = find.byWidgetPredicate((w) => w is Hero && w.tag == tag);
    expect(cardHero, findsOneWidget);

    await tester.tap(cardHero);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(pulseHeroShuttleKey),
      findsOneWidget,
      reason: 'in flight',
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Back'), findsOneWidget);
    expect(cardHero, findsOneWidget, reason: 'detail header carries $tag');
  });

  testWidgets('reduced motion skips Hero flight', (tester) async {
    await pumpApp(
      tester,
      dataset,
      initialLocation: '/pipeline',
      disableAnimations: true,
    );

    expect(find.text(_pipelineTitle), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(
      find.text('Probability unavailable').evaluate().isNotEmpty ||
          find.textContaining('% probability').evaluate().isNotEmpty,
      isTrue,
      reason: 'deal cards are on screen',
    );
    expect(_dealHeroes(), findsNothing);
  });

  testWidgets('double-tap on a deal card pushes one route', (tester) async {
    await pumpApp(tester, dataset, initialLocation: '/pipeline');
    await _scrollToFirstDeal(tester);
    final card = _dealHeroes().first;

    await tester.tap(card);
    await tester.pump(const Duration(milliseconds: 10));
    await tester.tap(card, warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(DealDetailScreen), findsNothing);
    expect(find.byType(PipelineScreen), findsOneWidget);
  });

  testWidgets('a deal on the hidden Pipeline tab does not fly into detail', (
    tester,
  ) async {
    await pumpApp(tester, dataset, initialLocation: '/pipeline');
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PipelineScreen)),
    );
    final attentionIds = {
      for (final item in container.read(analyticsBundleProvider).attention)
        if (item.route.startsWith('/deals/'))
          item.route.substring('/deals/'.length),
    };
    expect(attentionIds, isNotEmpty);

    Finder builtAttentionHero() => find.byWidgetPredicate(
      (w) => w is Hero && attentionIds.any((id) => w.tag == dealHeroTag(id)),
    );
    for (var i = 0; i < 30 && builtAttentionHero().evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -250));
      await tester.pumpAndSettle();
    }
    final tag = tester.widget<Hero>(builtAttentionHero().first).tag as String;
    final dealId = tag.substring('deal-card-'.length);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Overview'),
      ),
    );
    await tester.pumpAndSettle();
    final row = find.byWidgetPredicate(
      (w) =>
          w.runtimeType.toString() == '_AttentionRow' &&
          (w as dynamic).item.route == '/deals/$dealId',
    );
    for (var i = 0; i < 12 && row.evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();

    await tester.tap(row);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byKey(pulseHeroShuttleKey), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(DealDetailScreen), findsOneWidget);
  });
}
