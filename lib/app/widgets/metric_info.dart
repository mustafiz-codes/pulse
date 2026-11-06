import 'package:flutter/material.dart';

import '../../core/analytics/metric_definitions.dart';
import '../theme/app_colors.dart';

Future<void> showMetricDefinition(BuildContext context, String key) {
  final definition = metricDefinitions[key];
  if (definition == null) return Future.value();
  final palette = context.pulse;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: sheetContext.pulse.accentSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'METRIC DEFINITION',
                      style: Theme.of(sheetContext).textTheme.labelSmall
                          ?.copyWith(
                            color: sheetContext.pulse.accent,
                            fontSize: 9,
                          ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                definition.title,
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                definition.definition,
                style: Theme.of(sheetContext).textTheme.bodyLarge?.copyWith(
                  color: sheetContext.pulse.textSecondary,
                ),
              ),
              if (definition.caveat != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: palette.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          definition.caveat!,
                          style: Theme.of(sheetContext).textTheme.bodySmall
                              ?.copyWith(
                                color: palette.textSecondary,
                                height: 1.45,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class MetricInfoButton extends StatelessWidget {
  const MetricInfoButton({
    super.key,
    required this.metricKey,
    this.dense = false,
    this.color,
  });

  final String metricKey;
  final bool dense;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = context.pulse;
    return Tooltip(
      message: 'Metric definition',
      child: InkWell(
        onTap: () => showMetricDefinition(context, metricKey),
        borderRadius: BorderRadius.circular(99),
        child: Padding(
          padding: EdgeInsets.all(dense ? 3 : 5),
          child: Icon(
            Icons.info_outline_rounded,
            size: dense ? 14 : 17,
            color: color ?? palette.textMuted,
          ),
        ),
      ),
    );
  }
}
