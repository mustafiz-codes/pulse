import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/core/analytics/kpi_glossary.dart';
import 'package:pulse/core/analytics/metric_definitions.dart';

void main() {
  test('glossary renders every metric definition with caveats', () {
    final md = renderKpiGlossary(metricDefinitions);

    expect(md, startsWith('# PULSE KPI glossary'));
    expect(md, contains('## Booked sales value'));
    expect(
      md,
      contains(
        '> This is commercial won-deal value, not recognised or collected revenue.',
      ),
    );
    expect(
      RegExp(r'^## ', multiLine: true).allMatches(md).length,
      metricDefinitions.length,
    );
  });

  test('docs/KPI_GLOSSARY.md is in sync with the code', () {
    expect(
      File('docs/KPI_GLOSSARY.md').readAsStringSync(),
      renderKpiGlossary(metricDefinitions),
      reason: 'Run: dart run tool/export_kpi_glossary.dart',
    );
  });
}
