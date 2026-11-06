import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  /// Compile-time override used for screenshot and demo automation. The app
  /// defaults to light and the in-app toggle remains authoritative.
  static const _initial = String.fromEnvironment(
    'PULSE_INITIAL_THEME',
    defaultValue: 'light',
  );

  @override
  ThemeMode build() => _initial == 'dark' ? ThemeMode.dark : ThemeMode.light;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
