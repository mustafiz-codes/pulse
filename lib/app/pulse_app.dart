import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'splash/pulse_intro.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_provider.dart';

class PulseApp extends ConsumerWidget {
  const PulseApp({super.key, this.router});

  /// Optional router for widget tests; production uses the shared [appRouter].
  final GoRouter? router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'PULSE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router ?? appRouter,
      builder: (context, child) => PulseIntroHost(child: child!),
    );
  }
}
