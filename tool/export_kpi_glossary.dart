// Writes docs/KPI_GLOSSARY.md from the in-app metric definitions.
//
// Run from the project root:
//   dart run tool/export_kpi_glossary.dart
import 'dart:io';

import 'package:pulse/core/analytics/kpi_glossary.dart';
import 'package:pulse/core/analytics/metric_definitions.dart';

void main() {
  final file = File('docs/KPI_GLOSSARY.md');
  file.writeAsStringSync(renderKpiGlossary(metricDefinitions));
  stdout.writeln('Wrote ${file.path} (${metricDefinitions.length} metrics).');
}
