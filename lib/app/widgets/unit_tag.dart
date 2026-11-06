import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers.dart';
import '../theme/app_colors.dart';

/// Small pill naming a product and its unit ("Visa · Lawyer"), or just a
/// unit ("Lawyer"), tinted with the unit's colour.
class UnitTag extends ConsumerWidget {
  const UnitTag({super.key, this.unitId, this.productId})
    : assert(
        (unitId == null) != (productId == null),
        'Pass exactly one of unitId or productId',
      );

  final String? unitId;
  final String? productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataset = ref.watch(salesDatasetProvider);
    final palette = context.pulse;
    final resolvedUnitId = unitId ?? dataset.unitIdOf(productId!);
    final unit = dataset.unitsById[resolvedUnitId];
    final unitName = unit?.label ?? resolvedUnitId;
    final product = productId == null ? null : dataset.productsById[productId];
    final label = product == null ? unitName : '${product.label} · $unitName';
    final index = dataset.unitIds.indexOf(resolvedUnitId);
    final color = index < 0
        ? palette.textMuted
        : palette.unitColors[index % palette.unitColors.length];

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: palette.isDark ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 10.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
