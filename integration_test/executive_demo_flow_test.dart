import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pulse/app/bootstrap.dart';
import 'package:pulse/app/router.dart';
import 'package:pulse/app/widgets/layout.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  testWidgets('executive demo flow stays coherent end to end', (tester) async {
    await tester.pumpWidget(const PulseBootstrap());
    await _waitFor(tester, find.text('Executive overview'));
    // The cold-start intro plays once, then hands over to Overview.
    await _waitForGone(tester, find.byKey(const ValueKey('pulse-intro')));
    await tester.pumpAndSettle();

    expect(find.text('DEMO DATA'), findsWidgets);
    expect(find.text('Oct 2026'), findsWidgets);

    final navigation = find.byType(NavigationBar);

    await tester.tap(
      find.descendant(of: navigation, matching: find.text('Leads')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lead intelligence'), findsOneWidget);
    expect(find.text('DEMO DATA'), findsOneWidget);

    await tester.tap(
      find.descendant(of: navigation, matching: find.text('Pipeline')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sales pipeline'), findsOneWidget);

    appRouter.push('/deals/deal_0013');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.text('DEMO DATA'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Sales pipeline'), findsOneWidget);

    // PRD §11.4 executive demo path, in order.
    // 1. Overview offline, demo data clearly identified (asserted above).
    final navigationBar = find.byType(NavigationBar);
    await tester.tap(
      find.descendant(of: navigationBar, matching: find.text('Overview')),
    );
    await tester.pumpAndSettle();

    // 1b. Units: By unit → Lawyer → its pipeline → one Lawyer deal.
    final lawyer = find.descendant(
      of: find.byKey(const ValueKey('overview-by-unit')),
      matching: find.text('Lawyer'),
    );
    await _scrollTo(tester, lawyer);
    await tester.tap(lawyer.first);
    await tester.pumpAndSettle();
    expect(find.text('Top products'), findsOneWidget);
    final viewPipeline = find.text('View Lawyer pipeline');
    await _scrollTo(tester, viewPipeline);
    await tester.tap(viewPipeline);
    await tester.pumpAndSettle();
    expect(find.text('Sales pipeline'), findsOneWidget);
    final lawyerTag = find.textContaining('· Lawyer');
    await _scrollTo(tester, lawyerTag);
    await tester.tap(lawyerTag.first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Back'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset demo').last);
    await tester.pumpAndSettle();
    // Reset returns to the Overview tab (which keeps its scroll position).
    expect(tester.widget<NavigationBar>(navigationBar).selectedIndex, 0);
    expect(find.text('Oct 2026'), findsWidgets);

    // 2. Conversion: which stage has the longest dwell.
    appRouter.push('/conversion');
    await tester.pumpAndSettle();
    expect(find.text('Conversion analytics'), findsOneWidget);
    await _scrollTo(tester, find.textContaining('is the slowest stage'));
    expect(find.textContaining('is the slowest stage'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // 3. One representative deal and its dated stage milestones.
    appRouter.push('/deals/deal_0013');
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Stage timeline'));
    expect(find.text('Stage timeline'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // 4. Sales vs Operations: open the operations activity breakdown.
    appRouter.push('/workload');
    await tester.pumpAndSettle();
    final legend = find.descendant(
      of: find.byType(ShareLegend),
      matching: find.text('Operations'),
    );
    await _scrollTo(tester, legend);
    await tester.tap(legend.first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Operations activities'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    // 5. Team: compare with sample sizes, not bare rankings.
    await tester.tap(
      find.descendant(of: navigationBar, matching: find.text('Team')),
    );
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Win rate'));
    await tester.tap(find.text('Win rate'));
    await tester.pumpAndSettle();
    expect(find.textContaining('closed'), findsWidgets);
    expect(find.text('DEMO DATA'), findsOneWidget);

    // 6. Back to Overview for the management question.
    await tester.tap(
      find.descendant(of: navigationBar, matching: find.text('Overview')),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<NavigationBar>(navigationBar).selectedIndex, 0);
    expect(find.text('DEMO DATA'), findsWidgets);
  });
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 15 && finder.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

Future<void> _waitForGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isEmpty) return;
  }
  fail('Timed out waiting for $finder to disappear');
}

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}
