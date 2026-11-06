import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse/app/pulse_app.dart';
import 'package:pulse/app/router.dart';
import 'package:pulse/app/splash/intro_controller.dart';
import 'package:pulse/core/data/providers.dart';
import 'package:pulse/core/models/sales_dataset.dart';

/// Pumps the full app shell over [dataset] with a fresh router.
Future<GoRouter> pumpApp(
  WidgetTester tester,
  SalesDataset dataset, {
  String initialLocation = '/overview',
  Size size = const Size(430, 932),
  double textScale = 1,
  TextScaler? textScaler,
  bool disableAnimations = false,
  bool intro = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  if (disableAnimations) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
  }
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  final router = createAppRouter(initialLocation: initialLocation);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        salesDatasetProvider.overrideWithValue(dataset),
        introEnabledProvider.overrideWithValue(intro),
      ],
      child: textScaler == null
          ? PulseApp(router: router)
          : Builder(
              builder: (context) => MediaQuery(
                data: MediaQueryData.fromView(
                  View.of(context),
                ).copyWith(textScaler: textScaler),
                child: PulseApp(router: router),
              ),
            ),
    ),
  );
  if (intro) {
    await tester.pump();
  } else {
    await tester.pumpAndSettle();
  }
  return router;
}

/// Opens the header "⋯" menu and taps [label].
Future<void> tapMenuItem(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('More').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}
