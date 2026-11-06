import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/asset_json_data_source.dart';
import '../core/data/providers.dart';
import '../core/models/sales_dataset.dart';
import 'pulse_app.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/brand.dart';

/// Loads and validates the bundled fixture before any screen can render.
/// A failure shows a real diagnostic state rather than placeholder numbers.
class PulseBootstrap extends StatefulWidget {
  const PulseBootstrap({super.key});

  @override
  State<PulseBootstrap> createState() => _PulseBootstrapState();
}

class _PulseBootstrapState extends State<PulseBootstrap> {
  late Future<SalesDataset> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<SalesDataset> _load() => AssetJsonDataSource().load();

  void _retry() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SalesDataset>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            title: 'PULSE',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            home: const _BootstrapLoadingScreen(),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return MaterialApp(
            title: 'PULSE',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            home: _BootstrapErrorScreen(error: snapshot.error, onRetry: _retry),
          );
        }
        return ProviderScope(
          overrides: [salesDatasetProvider.overrideWithValue(snapshot.data!)],
          child: const PulseApp(),
        );
      },
    );
  }
}

/// Matches the native splash exactly (plain page colour) so the hand-off
/// into the animated intro never flashes. A small spinner appears only if
/// loading is unexpectedly slow.
class _BootstrapLoadingScreen extends StatefulWidget {
  const _BootstrapLoadingScreen();

  @override
  State<_BootstrapLoadingScreen> createState() =>
      _BootstrapLoadingScreenState();
}

class _BootstrapLoadingScreenState extends State<_BootstrapLoadingScreen> {
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    return Scaffold(
      backgroundColor: palette.background,
      body: Center(
        child: _slow
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.accent,
                  semanticsLabel: 'Preparing synthetic demo data',
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _BootstrapErrorScreen extends StatelessWidget {
  const _BootstrapErrorScreen({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    final theme = Theme.of(context);
    final detail = error?.toString() ?? 'Unknown data loading failure.';
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const BrandLockup(compact: true),
                      const SizedBox(width: 8),
                      const DemoDataBadge(dense: true),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Icon(
                    Icons.report_problem_outlined,
                    size: 32,
                    color: palette.coral,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Demo data could not be loaded',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PULSE will not show substitute or placeholder figures. '
                    'Fix the bundled fixture and try again.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.border),
                    ),
                    child: SelectableText(
                      kDebugMode
                          ? detail
                          : 'The bundled demo fixture failed validation. '
                                'Restart the app after correcting the asset.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                        height: 1.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 17),
                        label: const Text('Retry'),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Offline asset load',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
