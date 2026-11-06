import 'metric_definitions.dart';

/// Renders the in-app metric definitions as a Markdown glossary, so the
/// shipped document can never drift from the tooltips users actually see.
String renderKpiGlossary(Map<String, MetricDefinition> defs) {
  final out = StringBuffer()
    ..writeln('# PULSE KPI glossary')
    ..writeln()
    ..writeln(
      'Generated from `lib/core/analytics/metric_definitions.dart` by '
      '`dart run tool/export_kpi_glossary.dart`. Do not edit by hand.',
    );
  for (final def in defs.values) {
    out
      ..writeln()
      ..writeln('## ${def.title}')
      ..writeln()
      ..writeln(def.definition);
    if (def.caveat != null) {
      out
        ..writeln()
        ..writeln('> ${def.caveat}');
    }
  }
  return out.toString();
}
