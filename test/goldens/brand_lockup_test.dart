import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/app/theme/app_theme.dart';
import 'package:pulse/app/widgets/brand.dart';

import '../support/fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadInterFonts);

  testWidgets('brand lockup renders consistently', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        debugShowCheckedModeBanner: false,
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Center(
            child: RepaintBoundary(
              key: Key('brand-golden'),
              child: ColoredBox(
                color: Color(0xFF0B1020),
                child: SizedBox(
                  width: 320,
                  height: 120,
                  child: Center(child: BrandLockup()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('brand-golden')),
      matchesGoldenFile('brand_lockup.png'),
    );
  });
}
