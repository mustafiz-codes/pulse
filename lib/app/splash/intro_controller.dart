import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the animated intro is still on screen.
enum IntroPhase { playing, done }

/// Builds pass `--dart-define=PULSE_SKIP_INTRO=true` (screenshots, automation)
/// to start straight on Overview. Tests override this provider directly.
final introEnabledProvider = Provider<bool>(
  (ref) => !const bool.fromEnvironment('PULSE_SKIP_INTRO'),
);

class IntroPhaseNotifier extends Notifier<IntroPhase> {
  @override
  IntroPhase build() =>
      ref.watch(introEnabledProvider) ? IntroPhase.playing : IntroPhase.done;

  /// Ends the intro. Safe to call more than once.
  void finish() {
    if (state != IntroPhase.done) state = IntroPhase.done;
  }
}

/// Lives for the whole app session, so the intro plays once per cold start.
final introPhaseProvider = NotifierProvider<IntroPhaseNotifier, IntroPhase>(
  IntroPhaseNotifier.new,
);

/// Marks the header's logo tile so the intro can fly onto it.
final GlobalKey pulseHeaderLogoKey = GlobalKey(debugLabel: 'pulse-header-logo');
