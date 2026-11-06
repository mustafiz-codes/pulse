import '../models/deal.dart';
import 'analytics_scope.dart';

/// Booked and open figures for one business unit in the reporting window.
class UnitPerformance {
  const UnitPerformance({
    required this.unitId,
    required this.label,
    required this.bookedMinor,
    required this.previousBookedMinor,
    required this.wonCount,
    required this.openPipelineMinor,
    required this.openCount,
  });

  final String unitId;
  final String label;
  final int bookedMinor;
  final int previousBookedMinor;
  final int wonCount;
  final int openPipelineMinor;
  final int openCount;

  int get bookedDeltaMinor => bookedMinor - previousBookedMinor;
}

/// One product's contribution inside a unit.
class ProductPerformance {
  const ProductPerformance({
    required this.productId,
    required this.label,
    required this.bookedMinor,
    required this.wonCount,
    required this.openCount,
  });

  final String productId;
  final String label;
  final int bookedMinor;
  final int wonCount;
  final int openCount;
}

/// One rep's booked value inside a unit.
class UnitRepContribution {
  const UnitRepContribution({
    required this.userId,
    required this.bookedMinor,
    required this.wonCount,
    required this.openCount,
  });

  final String userId;
  final int bookedMinor;
  final int wonCount;
  final int openCount;
}

class UnitDetail {
  const UnitDetail({
    required this.unit,
    required this.products,
    required this.reps,
  });

  final UnitPerformance unit;

  /// Sorted by booked value (desc), then label.
  final List<ProductPerformance> products;

  /// Sorted by booked value (desc); reps with only open deals are included.
  final List<UnitRepContribution> reps;
}

/// Groups booked and open deals by the unit of each deal's own product.
///
/// Callers pass a scope; any unit filter on it is ignored so every unit's
/// figures stay comparable while the other filters (period, rep, source,
/// stage) still apply.
class UnitMetricsCalculator {
  const UnitMetricsCalculator();

  List<UnitPerformance> all(AnalyticsScope scope) {
    final unscoped = _withoutUnit(scope);
    final previous = unscoped.previous();
    return [
      for (final unit in scope.dataset.businessUnits)
        _performance(unscoped, previous, unit.id, unit.label),
    ];
  }

  UnitDetail detail(AnalyticsScope scope, String unitId) {
    final unscoped = _withoutUnit(scope);
    final dataset = scope.dataset;
    final unit = dataset.unitsById[unitId];
    final label = unit?.label ?? unitId;
    final performance = _performance(
      unscoped,
      unscoped.previous(),
      unitId,
      label,
    );
    bool inUnit(Deal deal) => dataset.unitIdOf(deal.productId) == unitId;
    final won = unscoped.wonDealsInWindow.where(inUnit).toList();
    final open = unscoped.openDealsSnapshot.where(inUnit).toList();

    final products =
        [
          for (final product in unit?.products ?? const [])
            ProductPerformance(
              productId: product.id,
              label: product.label,
              bookedMinor: _sum(won.where((d) => d.productId == product.id)),
              wonCount: won.where((d) => d.productId == product.id).length,
              openCount: open.where((d) => d.productId == product.id).length,
            ),
        ]..sort((a, b) {
          final byValue = b.bookedMinor.compareTo(a.bookedMinor);
          return byValue != 0 ? byValue : a.label.compareTo(b.label);
        });

    final owners = {
      ...won.map((d) => d.ownerId),
      ...open.map((d) => d.ownerId),
    };
    final reps =
        [
          for (final owner in owners)
            UnitRepContribution(
              userId: owner,
              bookedMinor: _sum(won.where((d) => d.ownerId == owner)),
              wonCount: won.where((d) => d.ownerId == owner).length,
              openCount: open.where((d) => d.ownerId == owner).length,
            ),
        ]..sort((a, b) {
          final byValue = b.bookedMinor.compareTo(a.bookedMinor);
          return byValue != 0 ? byValue : a.userId.compareTo(b.userId);
        });

    return UnitDetail(unit: performance, products: products, reps: reps);
  }

  UnitPerformance _performance(
    AnalyticsScope scope,
    AnalyticsScope previous,
    String unitId,
    String label,
  ) {
    bool inUnit(Deal deal) => scope.dataset.unitIdOf(deal.productId) == unitId;
    final won = scope.wonDealsInWindow.where(inUnit).toList();
    final open = scope.openDealsSnapshot.where(inUnit).toList();
    return UnitPerformance(
      unitId: unitId,
      label: label,
      bookedMinor: _sum(won),
      previousBookedMinor: _sum(previous.wonDealsInWindow.where(inUnit)),
      wonCount: won.length,
      openPipelineMinor: _sum(open),
      openCount: open.length,
    );
  }

  AnalyticsScope _withoutUnit(AnalyticsScope scope) =>
      scope.filter.unitId == null
      ? scope
      : AnalyticsScope(
          dataset: scope.dataset,
          filter: scope.filter.copyWith(unitId: null),
          window: scope.window,
        );

  int _sum(Iterable<Deal> deals) =>
      deals.fold<int>(0, (total, deal) => total + deal.valueMinor);
}
