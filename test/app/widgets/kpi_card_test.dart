import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app/theme/app_theme.dart';
import 'package:pulse/app/widgets/numbers.dart';
import 'package:pulse/app/widgets/section.dart';

import '../../support/fonts.dart';

void main() {
  setUpAll(loadInterFonts);

  testWidgets('KpiCard footnote is not truncated at 170px width', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 170,
              child: KpiCard(
                label: 'Win rate',
                value: Text('70%'),
                delta: DeltaChip(value: 29, label: '+29 pts'),
                footnote: '27 closed deals in period',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('27 closed deals in period'),
    );
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });
}
