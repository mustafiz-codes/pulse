import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app/theme/app_theme.dart';
import 'package:pulse/app/widgets/layout.dart';

void main() {
  testWidgets('share bar segments fill the bar height', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: StackedShareBar(
                segments: const [
                  ShareSegment(label: 'A', value: 3, color: Colors.blue),
                  ShareSegment(label: 'B', value: 1, color: Colors.teal),
                ],
                onSegmentTap: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final bar = find.byType(StackedShareBar);
    final barHeight = tester.getSize(bar).height;
    final fills = find.descendant(of: bar, matching: find.byType(ColoredBox));
    expect(fills, findsNWidgets(2));
    for (final element in fills.evaluate()) {
      final size = (element.renderObject! as RenderBox).size;
      expect(size.height, barHeight);
      expect(size.width, greaterThan(0));
    }
  });
}
