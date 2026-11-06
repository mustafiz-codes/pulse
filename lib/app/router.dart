import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/conversion/conversion_screen.dart';
import '../features/leads/lead_detail_screen.dart';
import '../features/leads/leads_screen.dart';
import '../features/overview/overview_screen.dart';
import '../features/pipeline/deal_detail_screen.dart';
import '../features/pipeline/pipeline_screen.dart';
import '../features/team/rep_detail_screen.dart';
import '../features/team/team_screen.dart';
import '../features/units/unit_detail_screen.dart';
import '../features/workload/workload_screen.dart';
import 'shell/pulse_shell.dart';
import 'theme/app_colors.dart';
import 'widgets/brand.dart';

/// Four persistent tabs plus secondary drill-downs on the root navigator.
/// Secondary routes are deliberately outside the shell so back navigation
/// returns to the originating tab with its state intact.
///
/// A fresh router can be created for widget tests; the production app uses the
/// single [appRouter] instance.
GoRouter createAppRouter({
  String initialLocation = const String.fromEnvironment(
    'PULSE_INITIAL_ROUTE',
    defaultValue: '/overview',
  ),
}) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute(
        builder: (context, state, navigationShell) =>
            PulseShell(navigationShell: navigationShell),
        navigatorContainerBuilder: _branchContainer,
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/overview',
                builder: (context, state) => const OverviewScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/leads',
                builder: (context, state) => const LeadsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pipeline',
                builder: (context, state) => const PipelineScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/team',
                builder: (context, state) => const TeamScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/conversion',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ConversionScreen(),
      ),
      GoRoute(
        path: '/workload',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const WorkloadScreen(),
      ),
      GoRoute(
        path: '/deals/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            DealDetailScreen(dealId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/units/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            UnitDetailScreen(unitId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/leads/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            LeadDetailScreen(leadId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/team/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            RepDetailScreen(repId: state.pathParameters['id']!),
      ),
    ],
    errorBuilder: (context, state) => _RouteErrorScreen(error: state.error),
  );
}

final GoRouter appRouter = createAppRouter();

/// Same as go_router's indexed stack, plus [HeroMode]: hidden tabs stay
/// mounted (to keep scroll and state) but their Heroes must not take part in
/// flights, or a deal opened from Overview would fly in from the invisible
/// Pipeline card.
Widget _branchContainer(
  BuildContext context,
  StatefulNavigationShell navigationShell,
  List<Widget> children,
) {
  final current = navigationShell.currentIndex;
  return IndexedStack(
    index: current,
    children: [
      for (var i = 0; i < children.length; i++)
        HeroMode(
          enabled: i == current,
          child: Offstage(
            offstage: i != current,
            child: TickerMode(enabled: i == current, child: children[i]),
          ),
        ),
    ],
  );
}

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const BrandLockup(compact: true),
        actions: const [DemoDataBadge(dense: true), SizedBox(width: 12)],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.explore_off_outlined,
                size: 34,
                color: palette.textMuted,
              ),
              const SizedBox(height: 12),
              Text('Screen not found', style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                error?.toString() ?? 'This internal route does not exist.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/overview'),
                child: const Text('Back to overview'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
