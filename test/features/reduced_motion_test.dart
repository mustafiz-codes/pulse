import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app/theme/app_theme.dart';
import 'package:pulse/app/widgets/numbers.dart';

void main() {
  testWidgets('AnimatedNumber renders its final value with zero duration', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: AnimatedNumber(value: 42, format: _formatWholeNumber),
          ),
        ),
      ),
    );
    await tester.pump();

    final builder = tester.widget<TweenAnimationBuilder<double>>(
      find.byType(TweenAnimationBuilder<double>),
    );
    expect(builder.duration, Duration.zero);
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('AnimatedNumber keeps its designed duration when motion is on', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: false),
          child: Scaffold(
            body: AnimatedNumber(value: 42, format: _formatWholeNumber),
          ),
        ),
      ),
    );
    await tester.pump();

    final builder = tester.widget<TweenAnimationBuilder<double>>(
      find.byType(TweenAnimationBuilder<double>),
    );
    expect(builder.duration, greaterThan(Duration.zero));
  });
}

String _formatWholeNumber(double value) => value.toStringAsFixed(0);
