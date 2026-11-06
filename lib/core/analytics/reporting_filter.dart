import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/dataset_manifest.dart';
import '../models/enums.dart';

enum PeriodPreset { last7Days, last30Days, thisMonth, quarter, custom }

extension PeriodPresetLabel on PeriodPreset {
  String get label => switch (this) {
    PeriodPreset.last7Days => '7 days',
    PeriodPreset.last30Days => '30 days',
    PeriodPreset.thisMonth => 'This month',
    PeriodPreset.quarter => 'Quarter',
    PeriodPreset.custom => 'Custom',
  };
}

class ReportWindow {
  const ReportWindow({
    required this.start,
    required this.end,
    required this.label,
  });

  final DateTime start;
  final DateTime end;
  final String label;

  Duration get duration => end.difference(start);

  ReportWindow get previous => ReportWindow(
    start: start.subtract(duration),
    end: start,
    label: 'Previous period',
  );

  bool contains(DateTime instant) =>
      !instant.isBefore(start) && instant.isBefore(end);

  bool overlaps(DateTime from, DateTime to) =>
      from.isBefore(end) && to.isAfter(start);
}

class ReportingFilter {
  const ReportingFilter({
    this.preset = PeriodPreset.thisMonth,
    this.customStart,
    this.customEnd,
    this.ownerId,
    this.unitId,
    this.source,
    this.stage,
    this.scenarioId,
  });

  final PeriodPreset preset;
  final DateTime? customStart;
  final DateTime? customEnd;
  final String? ownerId;
  final String? unitId;
  final LeadSource? source;
  final DealStage? stage;
  final String? scenarioId;

  static const Object _unset = Object();

  bool get hasAnyFilter =>
      ownerId != null || unitId != null || source != null || stage != null;

  ReportingFilter copyWith({
    PeriodPreset? preset,
    DateTime? customStart,
    DateTime? customEnd,
    Object? ownerId = _unset,
    Object? unitId = _unset,
    Object? source = _unset,
    Object? stage = _unset,
    Object? scenarioId = _unset,
  }) {
    return ReportingFilter(
      preset: preset ?? this.preset,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      ownerId: identical(ownerId, _unset) ? this.ownerId : ownerId as String?,
      unitId: identical(unitId, _unset) ? this.unitId : unitId as String?,
      source: identical(source, _unset) ? this.source : source as LeadSource?,
      stage: identical(stage, _unset) ? this.stage : stage as DealStage?,
      scenarioId: identical(scenarioId, _unset)
          ? this.scenarioId
          : scenarioId as String?,
    );
  }

  ReportingFilter clearContext() => ReportingFilter(
    preset: preset,
    customStart: customStart,
    customEnd: customEnd,
    scenarioId: scenarioId,
  );

  ReportWindow resolveWindow(DatasetManifest manifest) {
    final location = _location(manifest.timezone);
    final asOfLocal = tz.TZDateTime.from(manifest.asOf, location);
    final periodStartLocal = tz.TZDateTime.from(manifest.periodStart, location);
    final periodEndLocal = tz.TZDateTime.from(manifest.periodEnd, location);

    late tz.TZDateTime startLocal;
    late tz.TZDateTime endLocal;

    switch (preset) {
      case PeriodPreset.last7Days:
        endLocal = tz.TZDateTime(
          location,
          asOfLocal.year,
          asOfLocal.month,
          asOfLocal.day + 1,
        );
        startLocal = tz.TZDateTime(
          location,
          endLocal.year,
          endLocal.month,
          endLocal.day - 7,
        );
      case PeriodPreset.last30Days:
        endLocal = tz.TZDateTime(
          location,
          asOfLocal.year,
          asOfLocal.month,
          asOfLocal.day + 1,
        );
        startLocal = tz.TZDateTime(
          location,
          endLocal.year,
          endLocal.month,
          endLocal.day - 30,
        );
      case PeriodPreset.thisMonth:
        startLocal = tz.TZDateTime(
          location,
          asOfLocal.year,
          asOfLocal.month,
          1,
        );
        endLocal = tz.TZDateTime(
          location,
          asOfLocal.year,
          asOfLocal.month + 1,
          1,
        );
      case PeriodPreset.quarter:
        startLocal = tz.TZDateTime(
          location,
          asOfLocal.year,
          asOfLocal.month - 2,
          1,
        );
        endLocal = tz.TZDateTime(
          location,
          asOfLocal.year,
          asOfLocal.month + 1,
          1,
        );
      case PeriodPreset.custom:
        final start = customStart;
        final end = customEnd;
        if (start == null || end == null || !start.isBefore(end)) {
          startLocal = tz.TZDateTime(
            location,
            asOfLocal.year,
            asOfLocal.month,
            1,
          );
          endLocal = tz.TZDateTime(
            location,
            asOfLocal.year,
            asOfLocal.month + 1,
            1,
          );
        } else {
          startLocal = tz.TZDateTime(
            location,
            start.year,
            start.month,
            start.day,
          );
          endLocal = tz.TZDateTime(location, end.year, end.month, end.day + 1);
        }
    }

    if (startLocal.isBefore(periodStartLocal)) startLocal = periodStartLocal;
    if (endLocal.isAfter(periodEndLocal)) endLocal = periodEndLocal;
    if (!startLocal.isBefore(endLocal)) {
      startLocal = tz.TZDateTime(location, asOfLocal.year, asOfLocal.month, 1);
      endLocal = tz.TZDateTime(
        location,
        asOfLocal.year,
        asOfLocal.month + 1,
        1,
      );
    }

    return ReportWindow(
      start: startLocal.toUtc(),
      end: endLocal.toUtc(),
      label: _label(startLocal, endLocal),
    );
  }

  String _label(tz.TZDateTime startLocal, tz.TZDateTime endLocal) {
    switch (preset) {
      case PeriodPreset.last7Days:
        return 'Last 7 days';
      case PeriodPreset.last30Days:
        return 'Last 30 days';
      case PeriodPreset.thisMonth:
        return DateFormat('MMMM yyyy').format(startLocal);
      case PeriodPreset.quarter:
        final lastDay = endLocal.subtract(const Duration(days: 1));
        return '${DateFormat('MMM').format(startLocal)} – '
            '${DateFormat('MMM yyyy').format(lastDay)}';
      case PeriodPreset.custom:
        final lastDay = endLocal.subtract(const Duration(days: 1));
        return '${DateFormat('d MMM').format(startLocal)} – '
            '${DateFormat('d MMM yyyy').format(lastDay)}';
    }
  }

  tz.Location _location(String timezone) {
    try {
      return tz.getLocation(timezone);
    } catch (_) {
      return tz.UTC;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReportingFilter &&
          other.preset == preset &&
          other.customStart == customStart &&
          other.customEnd == customEnd &&
          other.ownerId == ownerId &&
          other.unitId == unitId &&
          other.source == source &&
          other.stage == stage &&
          other.scenarioId == scenarioId;

  @override
  int get hashCode => Object.hash(
    preset,
    customStart,
    customEnd,
    ownerId,
    unitId,
    source,
    stage,
    scenarioId,
  );
}

class ReportingFilterNotifier extends Notifier<ReportingFilter> {
  @override
  ReportingFilter build() => const ReportingFilter();

  void setPreset(PeriodPreset preset) {
    state = state.copyWith(preset: preset, scenarioId: null);
  }

  void setCustomRange(DateTime start, DateTime end) {
    state = state.copyWith(
      preset: PeriodPreset.custom,
      customStart: start,
      customEnd: end,
      scenarioId: null,
    );
  }

  void setOwner(String? ownerId) {
    state = state.copyWith(ownerId: ownerId, scenarioId: null);
  }

  void setUnit(String? unitId) {
    state = state.copyWith(unitId: unitId, scenarioId: null);
  }

  void setSource(LeadSource? source) {
    state = state.copyWith(source: source, scenarioId: null);
  }

  void setStage(DealStage? stage) {
    state = state.copyWith(stage: stage, scenarioId: null);
  }

  void applyScenario({
    required String id,
    required PeriodPreset preset,
    String? unitId,
    String? ownerId,
    DealStage? stage,
  }) {
    state = ReportingFilter(
      preset: preset,
      unitId: unitId,
      ownerId: ownerId,
      stage: stage,
      scenarioId: id,
    );
  }

  void reset() {
    state = const ReportingFilter();
  }
}

final reportingFilterProvider =
    NotifierProvider<ReportingFilterNotifier, ReportingFilter>(
      ReportingFilterNotifier.new,
    );
