import 'package:timezone/timezone.dart' as tz;

import 'analytics_scope.dart';

class TargetCoverage {
  const TargetCoverage({
    required this.targetMinor,
    required this.includedOwnerMonths,
    required this.missingOwnerMonths,
    this.unitFiltered = false,
  });

  final int? targetMinor;
  final int includedOwnerMonths;
  final int missingOwnerMonths;

  /// Targets are per rep, so a unit-filtered view has none (never invented).
  final bool unitFiltered;

  bool get hasTarget => targetMinor != null && targetMinor! > 0;

  bool get hasPartialCoverage =>
      includedOwnerMonths > 0 && missingOwnerMonths > 0;
}

class TargetCalculator {
  const TargetCalculator();

  TargetCoverage forScope(AnalyticsScope scope, {Iterable<String>? ownerIds}) {
    if (scope.filter.unitId != null) {
      return const TargetCoverage(
        targetMinor: null,
        includedOwnerMonths: 0,
        missingOwnerMonths: 0,
        unitFiltered: true,
      );
    }
    final owners = (ownerIds ?? scope.matchingUsers.map((user) => user.id))
        .toSet();
    if (owners.isEmpty) {
      return const TargetCoverage(
        targetMinor: null,
        includedOwnerMonths: 0,
        missingOwnerMonths: 0,
      );
    }

    final dataset = scope.dataset;
    final location = _location(dataset.manifest.timezone);
    final windowStart = scope.window.start;
    final windowEnd = scope.window.end;

    var cursor = tz.TZDateTime.from(windowStart, location);
    cursor = tz.TZDateTime(location, cursor.year, cursor.month, 1);

    var total = 0.0;
    var included = 0;
    var missing = 0;

    while (cursor.toUtc().isBefore(windowEnd)) {
      final monthStart = cursor;
      final monthEnd = tz.TZDateTime(
        location,
        cursor.year,
        cursor.month + 1,
        1,
      );
      final monthStartUtc = monthStart.toUtc();
      final monthEndUtc = monthEnd.toUtc();

      final overlapStart = windowStart.isAfter(monthStartUtc)
          ? windowStart
          : monthStartUtc;
      final overlapEnd = windowEnd.isBefore(monthEndUtc)
          ? windowEnd
          : monthEndUtc;
      final monthSeconds = monthEndUtc.difference(monthStartUtc).inSeconds;
      final overlapSeconds = overlapEnd.difference(overlapStart).inSeconds;
      final fraction = monthSeconds == 0 ? 0.0 : overlapSeconds / monthSeconds;

      final monthLabel =
          '${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}';

      for (final ownerId in owners) {
        final target = dataset.targetFor(ownerId, monthLabel);
        if (target == null) {
          missing++;
        } else {
          total += target.wonValueTargetMinor * fraction;
          included++;
        }
      }

      cursor = monthEnd;
    }

    return TargetCoverage(
      targetMinor: included == 0 ? null : total.round(),
      includedOwnerMonths: included,
      missingOwnerMonths: missing,
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
