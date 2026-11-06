import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app/theme/app_motion.dart';
import 'package:pulse/app/widgets/animated_reorder_column.dart';

Widget _host(List<String> ids, {bool disableAnimations = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(
        body: SingleChildScrollView(
          child: AnimatedReorderColumn(
            ids: ids,
            itemExtent: 60,
            itemBuilder: (context, i) => Text('row-${ids[i]}'),
          ),
        ),
      ),
    ),
  );
}

double _top(WidgetTester tester, String id) =>
    tester.getTopLeft(find.text('row-$id')).dy;

void main() {
  testWidgets('rows glide to new positions', (tester) async {
    await tester.pumpWidget(_host(['a', 'b', 'c']));
    expect(_top(tester, 'c'), 120);

    await tester.pumpWidget(_host(['c', 'a', 'b']));
    await tester.pump(AppMotion.standard ~/ 2);
    final mid = _top(tester, 'c');
    expect(mid, greaterThan(0));
    expect(mid, lessThan(120));

    await tester.pumpAndSettle();
    expect(_top(tester, 'c'), 0);
    expect(_top(tester, 'a'), 60);
    expect(_top(tester, 'b'), 120);
  });

  testWidgets('reduced motion snaps', (tester) async {
    await tester.pumpWidget(_host(['a', 'b', 'c'], disableAnimations: true));
    await tester.pumpWidget(_host(['c', 'a', 'b'], disableAnimations: true));
    await tester.pump();
    expect(_top(tester, 'c'), 0);
  });

  testWidgets('height tracks item count', (tester) async {
    await tester.pumpWidget(_host(['a', 'b', 'c']));
    expect(tester.getSize(find.byType(AnimatedReorderColumn)).height, 180);
    await tester.pumpWidget(_host(['a']));
    expect(tester.getSize(find.byType(AnimatedReorderColumn)).height, 60);
  });
}
