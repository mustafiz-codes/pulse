import 'package:flutter/services.dart';

/// Haptic vocabulary for PULSE. Kept deliberately small: a light click for
/// meaningful selections and a slightly firmer tap for confirming a reset.
/// Android and iOS already honour the user's system haptics setting.
abstract final class PulseHaptics {
  static Future<void> selection() => HapticFeedback.selectionClick();

  static Future<void> confirm() => HapticFeedback.lightImpact();
}
