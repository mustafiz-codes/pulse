import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the bundled Inter faces into the test renderer. Without this, widget
/// tests use the Ahem test font, whose square glyphs produce unrealistic
/// layout widths and hide (or invent) overflow problems.
Future<void> loadInterFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = FontLoader('Inter');
  for (final file in const [
    'Inter-Regular.ttf',
    'Inter-Medium.ttf',
    'Inter-SemiBold.ttf',
    'Inter-Bold.ttf',
    'Inter-ExtraBold.ttf',
  ]) {
    loader.addFont(rootBundle.load('assets/fonts/$file'));
  }
  await loader.load();
}
