import 'dart:convert';
import 'dart:io';

import 'package:pulse/core/models/sales_dataset.dart';

const demoAssetFiles = <String>[
  'manifest',
  'users',
  'accounts',
  'leads',
  'deals',
  'deal_stage_events',
  'activities',
  'targets',
  'insight_scenarios',
  'business_units',
];

/// Loads the checked-in fixture from disk so data tests do not depend on the
/// Flutter asset bundle.
Future<SalesDataset> loadDemoDataset({
  String basePath = 'assets/data/demo',
}) async {
  final raw = <String, dynamic>{};
  for (final name in demoAssetFiles) {
    final file = File('$basePath/$name.json');
    raw[name] = jsonDecode(await file.readAsString());
  }
  return SalesDataset.fromJson(raw);
}
