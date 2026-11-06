import 'package:timezone/timezone.dart' as tz;

import '../models/enums.dart';
import '../models/sales_activity.dart';
import '../models/sales_user.dart';
import '../utils/date_format.dart';
import 'analytics_scope.dart';
import 'math_utils.dart';

class WorkloadCategoryBreakdown {
  const WorkloadCategoryBreakdown({
    required this.category,
    required this.minutes,
    required this.share,
  });

  final WorkCategory category;
  final int minutes;
  final double share;
}

class WorkloadSubcategoryBreakdown {
  const WorkloadSubcategoryBreakdown({
    required this.category,
    required this.subcategory,
    required this.minutes,
    required this.share,
  });

  final WorkCategory category;
  final String subcategory;
  final int minutes;
  final double share;
}

class RepWorkload {
  const RepWorkload({
    required this.user,
    required this.salesMinutes,
    required this.operationsMinutes,
    required this.otherMinutes,
    required this.totalMinutes,
    required this.eligibleActivities,
    required this.validActivities,
    required this.coverage,
  });

  final SalesUser user;
  final int salesMinutes;
  final int operationsMinutes;
  final int otherMinutes;
  final int totalMinutes;
  final int eligibleActivities;
  final int validActivities;
  final double? coverage;

  double? get operationsShare =>
      totalMinutes == 0 ? null : operationsMinutes / totalMinutes;

  double? get salesShare =>
      totalMinutes == 0 ? null : salesMinutes / totalMinutes;

  bool get hasLoggedTime => totalMinutes > 0;
}

class WorkloadTrendPoint {
  const WorkloadTrendPoint({
    required this.label,
    required this.salesMinutes,
    required this.operationsMinutes,
    required this.otherMinutes,
  });

  final String label;
  final int salesMinutes;
  final int operationsMinutes;
  final int otherMinutes;

  int get totalMinutes => salesMinutes + operationsMinutes + otherMinutes;
}

class WorkloadMetrics {
  const WorkloadMetrics({
    required this.salesMinutes,
    required this.operationsMinutes,
    required this.otherMinutes,
    required this.totalMinutes,
    required this.categories,
    required this.subcategories,
    required this.reps,
    required this.trend,
    required this.eligibleActivities,
    required this.validActivities,
    required this.missingDurationActivities,
    required this.estimatedActivities,
    required this.unknownCategoryActivities,
    required this.coverage,
  });

  final int salesMinutes;
  final int operationsMinutes;
  final int otherMinutes;
  final int totalMinutes;
  final List<WorkloadCategoryBreakdown> categories;
  final List<WorkloadSubcategoryBreakdown> subcategories;
  final List<RepWorkload> reps;
  final List<WorkloadTrendPoint> trend;
  final int eligibleActivities;
  final int validActivities;
  final int missingDurationActivities;
  final int estimatedActivities;
  final int unknownCategoryActivities;
  final double? coverage;

  double? get operationsShare =>
      totalMinutes == 0 ? null : operationsMinutes / totalMinutes;

  double? get salesShare =>
      totalMinutes == 0 ? null : salesMinutes / totalMinutes;

  double? get otherShare =>
      totalMinutes == 0 ? null : otherMinutes / totalMinutes;

  bool get insufficient => totalMinutes < 60 || validActivities < 5;

  RepWorkload? get topOperationsRep {
    final withTime = reps.where((rep) => rep.hasLoggedTime).toList();
    if (withTime.isEmpty) return null;
    withTime.sort((a, b) {
      final compare = b.operationsMinutes.compareTo(a.operationsMinutes);
      if (compare != 0) return compare;
      return b.totalMinutes.compareTo(a.totalMinutes);
    });
    return withTime.first;
  }
}

class WorkloadMetricsCalculator {
  const WorkloadMetricsCalculator();

  WorkloadMetrics compute(AnalyticsScope scope) {
    final activities = scope.activitiesInWindow.toList(growable: false);
    final valid = activities
        .where(
          (activity) =>
              activity.hasValidLoggedDuration &&
              activity.workCategory != WorkCategory.unknown,
        )
        .toList(growable: false);

    final sales = _sum(valid, WorkCategory.sales);
    final operations = _sum(valid, WorkCategory.operations);
    final other = _sum(valid, WorkCategory.other);
    final total = sales + operations + other;

    final categories = [
      for (final category in const [
        WorkCategory.sales,
        WorkCategory.operations,
        WorkCategory.other,
      ])
        WorkloadCategoryBreakdown(
          category: category,
          minutes: _sum(valid, category),
          share: total == 0 ? 0 : _sum(valid, category) / total,
        ),
    ];

    final subcategoryTotals = <String, int>{};
    final subcategoryCategory = <String, WorkCategory>{};
    for (final activity in valid) {
      final key = '${activity.workCategory.name}|${activity.workSubcategory}';
      subcategoryTotals[key] =
          (subcategoryTotals[key] ?? 0) + (activity.durationMinutes ?? 0);
      subcategoryCategory[key] = activity.workCategory;
    }
    final subcategories =
        subcategoryTotals.entries
            .map(
              (entry) => WorkloadSubcategoryBreakdown(
                category: subcategoryCategory[entry.key]!,
                subcategory: entry.key.split('|').last,
                minutes: entry.value,
                share: total == 0 ? 0 : entry.value / total,
              ),
            )
            .toList()
          ..sort((a, b) => b.minutes.compareTo(a.minutes));

    final reps = <RepWorkload>[];
    for (final user in scope.matchingUsers) {
      final ownerActivities = activities
          .where((activity) => activity.ownerId == user.id)
          .toList(growable: false);
      final ownerValid = ownerActivities
          .where(
            (activity) =>
                activity.hasValidLoggedDuration &&
                activity.workCategory != WorkCategory.unknown,
          )
          .toList(growable: false);
      final ownerTotal = ownerValid.fold<int>(
        0,
        (sum, activity) => sum + (activity.durationMinutes ?? 0),
      );
      reps.add(
        RepWorkload(
          user: user,
          salesMinutes: _sum(ownerValid, WorkCategory.sales),
          operationsMinutes: _sum(ownerValid, WorkCategory.operations),
          otherMinutes: _sum(ownerValid, WorkCategory.other),
          totalMinutes: ownerTotal,
          eligibleActivities: ownerActivities.length,
          validActivities: ownerValid.length,
          coverage: safeRate(ownerValid.length, ownerActivities.length),
        ),
      );
    }
    reps.sort((a, b) {
      final compare = b.operationsMinutes.compareTo(a.operationsMinutes);
      if (compare != 0) return compare;
      return b.totalMinutes.compareTo(a.totalMinutes);
    });

    return WorkloadMetrics(
      salesMinutes: sales,
      operationsMinutes: operations,
      otherMinutes: other,
      totalMinutes: total,
      categories: categories,
      subcategories: subcategories,
      reps: reps,
      trend: _buildTrend(scope, valid),
      eligibleActivities: activities.length,
      validActivities: valid.length,
      missingDurationActivities: activities
          .where((activity) => activity.durationMinutes == null)
          .length,
      estimatedActivities: activities
          .where((activity) => activity.timeQuality == TimeQuality.estimated)
          .length,
      unknownCategoryActivities: activities
          .where((activity) => activity.workCategory == WorkCategory.unknown)
          .length,
      coverage: safeRate(valid.length, activities.length),
    );
  }

  int _sum(List<SalesActivity> activities, WorkCategory category) => activities
      .where((activity) => activity.workCategory == category)
      .fold<int>(0, (sum, activity) => sum + (activity.durationMinutes ?? 0));

  List<WorkloadTrendPoint> _buildTrend(
    AnalyticsScope scope,
    List<SalesActivity> activities,
  ) {
    final durationDays = scope.window.duration.inHours / 24;
    if (durationDays <= 14) {
      return _dailyTrend(scope, activities);
    }
    if (durationDays <= 70) {
      return _weeklyTrend(scope, activities);
    }
    return _monthlyTrend(scope, activities);
  }

  List<WorkloadTrendPoint> _dailyTrend(
    AnalyticsScope scope,
    List<SalesActivity> activities,
  ) {
    final points = <WorkloadTrendPoint>[];
    var cursor = DateTime.utc(
      scope.window.start.year,
      scope.window.start.month,
      scope.window.start.day,
    );
    while (cursor.isBefore(scope.window.end)) {
      final end = cursor.add(const Duration(days: 1));
      points.add(
        _pointFor(
          label: formatDayMonth(cursor),
          activities: activities,
          start: cursor,
          end: end,
        ),
      );
      cursor = end;
    }
    return points;
  }

  List<WorkloadTrendPoint> _weeklyTrend(
    AnalyticsScope scope,
    List<SalesActivity> activities,
  ) {
    final points = <WorkloadTrendPoint>[];
    var cursor = scope.window.start;
    while (cursor.isBefore(scope.window.end)) {
      final end = cursor.add(const Duration(days: 7));
      points.add(
        _pointFor(
          label: formatDayMonth(cursor),
          activities: activities,
          start: cursor,
          end: end,
        ),
      );
      cursor = end;
    }
    return points;
  }

  List<WorkloadTrendPoint> _monthlyTrend(
    AnalyticsScope scope,
    List<SalesActivity> activities,
  ) {
    final location = _location(scope.dataset.manifest.timezone);
    var cursor = tz.TZDateTime.from(scope.window.start, location);
    cursor = tz.TZDateTime(location, cursor.year, cursor.month, 1);
    final points = <WorkloadTrendPoint>[];
    while (cursor.toUtc().isBefore(scope.window.end)) {
      final end = tz.TZDateTime(location, cursor.year, cursor.month + 1, 1);
      points.add(
        _pointFor(
          label: formatShortMonthYear(cursor.toUtc()),
          activities: activities,
          start: cursor.toUtc(),
          end: end.toUtc(),
        ),
      );
      cursor = end;
    }
    return points;
  }

  WorkloadTrendPoint _pointFor({
    required String label,
    required List<SalesActivity> activities,
    required DateTime start,
    required DateTime end,
  }) {
    final inBucket = activities.where(
      (activity) =>
          !activity.startedAt.isBefore(start) &&
          activity.startedAt.isBefore(end),
    );
    return WorkloadTrendPoint(
      label: label,
      salesMinutes: _sum(inBucket.toList(), WorkCategory.sales),
      operationsMinutes: _sum(inBucket.toList(), WorkCategory.operations),
      otherMinutes: _sum(inBucket.toList(), WorkCategory.other),
    );
  }

  tz.Location _location(String timezone) {
    try {
      return tz.getLocation(timezone);
    } catch (_) {
      return tz.UTC;
    }
  }
}

/// Every activity in [scope]'s window and owner/team filter whose work
/// category is [category], newest first. Unlike the time-share calculation
/// this deliberately keeps records without a valid duration, so a drill-down
/// can show them as "Not recorded" rather than hiding them.
List<SalesActivity> activitiesForCategory(
  AnalyticsScope scope,
  WorkCategory category,
) {
  return scope.activitiesInWindow
      .where((activity) => activity.workCategory == category)
      .toList()
    ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
}
