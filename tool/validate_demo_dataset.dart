// Validates the checked-in PULSE demo fixture.
//
// Run from the project root:
//   dart run tool/validate_demo_dataset.dart
//
// Exits with code 1 if any validation error is found.

import 'dart:convert';
import 'dart:io';

import 'package:pulse/core/data/data_validation.dart';
import 'package:pulse/core/models/sales_dataset.dart';

const _files = <String>[
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

void main() {
  final raw = <String, dynamic>{};
  for (final name in _files) {
    final file = File('assets/data/demo/$name.json');
    if (!file.existsSync()) {
      stderr.writeln('Missing $file');
      exitCode = 1;
      return;
    }
    raw[name] = jsonDecode(file.readAsStringSync());
  }

  final dataset = SalesDataset.fromJson(raw);
  final result = const DataValidator().validate(dataset);

  stdout.writeln('PULSE demo dataset: ${dataset.manifest.datasetId}');
  stdout.writeln('  as of: ${dataset.manifest.asOf.toIso8601String()}');
  stdout.writeln('  users: ${dataset.users.length}');
  stdout.writeln('  accounts: ${dataset.accounts.length}');
  stdout.writeln('  leads: ${dataset.leads.length}');
  stdout.writeln('  deals: ${dataset.deals.length}');
  stdout.writeln('  stage events: ${dataset.stageEvents.length}');
  stdout.writeln('  activities: ${dataset.activities.length}');
  stdout.writeln('  targets: ${dataset.targets.length}');
  stdout.writeln('  scenarios: ${dataset.scenarios.length}');
  stdout.writeln(
    '  warnings: ${result.warnings.length}, errors: ${result.errors.length}',
  );

  for (final warning in result.warnings.take(12)) {
    stdout.writeln('  warning: $warning');
  }
  if (result.warnings.length > 12) {
    stdout.writeln('  …and ${result.warnings.length - 12} more warnings');
  }

  for (final error in result.errors) {
    stderr.writeln('  error: $error');
  }

  if (!result.isValid) {
    exitCode = 1;
    return;
  }

  stdout.writeln('Validation passed.');
}
