import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../feedback/haptics.dart';
import '../theme/app_colors.dart';
import '../widgets/background.dart';
import '../widgets/content_width.dart';
import '../widgets/brand.dart';
import '../widgets/top_bar.dart';

class PulseShell extends StatelessWidget {
  const PulseShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final iconBrightness = palette.isDark ? Brightness.light : Brightness.dark;
    // Tab screens have no AppBar, so set the system bars here to match the
    // in-app theme (not the phone's own light/dark setting).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness: palette.isDark
            ? Brightness.dark
            : Brightness.light,
        systemNavigationBarColor: palette.surface,
        systemNavigationBarIconBrightness: iconBrightness,
      ),
      child: Scaffold(
        backgroundColor: palette.background,
        body: PulseBackground(
          heroWash: navigationShell.currentIndex == 0,
          child: SafeArea(
            bottom: false,
            child: PulseContentWidth(
              child: Column(
                children: [
                  const PulseTopBar(),
                  Expanded(child: navigationShell),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: palette.border)),
          ),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) {
              if (index != navigationShell.currentIndex) {
                PulseHaptics.selection();
              }
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.space_dashboard_outlined),
                selectedIcon: Icon(Icons.space_dashboard_rounded),
                label: 'Overview',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_search_outlined),
                selectedIcon: Icon(Icons.person_search_rounded),
                label: 'Leads',
              ),
              NavigationDestination(
                icon: Icon(Icons.view_kanban_outlined),
                selectedIcon: Icon(Icons.view_kanban_rounded),
                label: 'Pipeline',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups_rounded),
                label: 'Team',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PulseDetailScaffold extends ConsumerWidget {
  const PulseDetailScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.bottomNavigationBar,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.pulse;
    final router = GoRouter.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (router.canPop()) {
              router.pop();
            } else {
              router.go('/overview');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            if (subtitle != null)
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.textMuted,
                  fontSize: 10.5,
                ),
              ),
          ],
        ),
        actions: [
          const DemoDataBadge(dense: true),
          const SizedBox(width: 2),
          const PulseOverflowMenu(),
          const SizedBox(width: 6),
          ...?actions,
        ],
      ),
      body: PulseBackground(
        child: SafeArea(top: false, child: PulseContentWidth(child: child)),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
