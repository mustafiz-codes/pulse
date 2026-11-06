import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app/theme/app_motion.dart';
import 'package:pulse/app/widgets/entrance_fade.dart';

Widget _host(Object key, {bool disableAnimations = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(
      body: EntranceFade(key: ValueKey(key), child: const Text('item')),
    ),
  ),
);

double _opacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.ancestor(of: find.text('item'), matching: find.byType(Opacity)),
    )
    .opacity;

void main() {
  testWidgets('fades in again when its key changes', (tester) async {
    await tester.pumpWidget(_host('a'));
    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);

    await tester.pumpWidget(_host('b'));
    await tester.pump(AppMotion.standard ~/ 3);
    expect(_opacity(tester), lessThan(1));

    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);
  });

  testWidgets('reduced motion shows the item immediately', (tester) async {
    await tester.pumpWidget(_host('a', disableAnimations: true));
    await tester.pump();
    expect(_opacity(tester), 1);
  });
}
