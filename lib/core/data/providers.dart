import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics_bundle.dart';
import '../analytics/reporting_filter.dart';
import '../analytics/unit_metrics.dart';
import '../models/insight_scenario.dart';
import '../models/sales_dataset.dart';
import '../models/sales_user.dart';
import 'repositories/activity_repository.dart';
import 'repositories/deal_repository.dart';
import 'repositories/lead_repository.dart';
import 'repositories/team_repository.dart';

/// The single loaded fixture. `main` overrides this after validation so no
/// screen can ever render placeholder numbers while data is missing.
final salesDatasetProvider = Provider<SalesDataset>(
  (ref) => throw StateError('Demo dataset has not been loaded'),
);

final leadRepositoryProvider = Provider<LeadRepository>(
  (ref) => LeadRepository(ref.watch(salesDatasetProvider)),
);

final dealRepositoryProvider = Provider<DealRepository>(
  (ref) => DealRepository(ref.watch(salesDatasetProvider)),
);

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(ref.watch(salesDatasetProvider)),
);

final teamRepositoryProvider = Provider<TeamRepository>(
  (ref) => TeamRepository(ref.watch(salesDatasetProvider)),
);

final analyticsBundleProvider = Provider<AnalyticsBundle>((ref) {
  final dataset = ref.watch(salesDatasetProvider);
  final filter = ref.watch(reportingFilterProvider);
  return AnalyticsBundle.compute(dataset: dataset, filter: filter);
});

final activeUserProvider = Provider.family<SalesUser?, String>((ref, id) {
  return ref.watch(salesDatasetProvider).usersById[id];
});

final scenarioProvider = Provider.family<InsightScenario?, String>((ref, id) {
  final scenarios = ref.watch(salesDatasetProvider).scenarios;
  for (final scenario in scenarios) {
    if (scenario.id == id) return scenario;
  }
  return null;
});

/// Unit detail for the current reporting filter (unit filter ignored).
final unitDetailProvider = Provider.family<UnitDetail, String>((ref, unitId) {
  final bundle = ref.watch(analyticsBundleProvider);
  return const UnitMetricsCalculator().detail(bundle.scope, unitId);
});
