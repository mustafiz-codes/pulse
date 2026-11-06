import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../analytics/reporting_filter.dart';

const String defaultTimezone = 'Europe/London';

tz.TZDateTime inZone(DateTime instant, [String timezone = defaultTimezone]) {
  try {
    return tz.TZDateTime.from(instant, tz.getLocation(timezone));
  } catch (_) {
    return tz.TZDateTime.from(instant, tz.UTC);
  }
}

String formatDate(
  DateTime instant, {
  String pattern = 'd MMM yyyy',
  String timezone = defaultTimezone,
}) => DateFormat(pattern).format(inZone(instant, timezone));

String formatMonthYear(DateTime instant, {String timezone = defaultTimezone}) =>
    DateFormat('MMMM yyyy').format(inZone(instant, timezone));

String formatShortMonthYear(
  DateTime instant, {
  String timezone = defaultTimezone,
}) => DateFormat('MMM yyyy').format(inZone(instant, timezone));

String formatDateTime(
  DateTime instant, {
  String pattern = 'd MMM yyyy, HH:mm',
  String timezone = defaultTimezone,
}) => DateFormat(pattern).format(inZone(instant, timezone));

String formatDayMonth(DateTime instant, {String timezone = defaultTimezone}) =>
    DateFormat('d MMM').format(inZone(instant, timezone));

String formatWeekdayDayMonth(
  DateTime instant, {
  String timezone = defaultTimezone,
}) => DateFormat('EEE d MMM').format(inZone(instant, timezone));

String formatDurationDays(double days) {
  if (days < 1) {
    final hours = (days * 24).round();
    return '$hours ${hours == 1 ? 'hour' : 'hours'}';
  }
  final rounded = days < 10 ? days.toStringAsFixed(1) : days.round().toString();
  final normalized = rounded.endsWith('.0')
      ? rounded.substring(0, rounded.length - 2)
      : rounded;
  return '$normalized ${normalized == '1' ? 'day' : 'days'}';
}

String formatDurationHours(double hours) {
  if (hours < 1) {
    final minutes = (hours * 60).round();
    return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
  }
  final rounded = hours < 10
      ? hours.toStringAsFixed(1)
      : hours.round().toString();
  final normalized = rounded.endsWith('.0')
      ? rounded.substring(0, rounded.length - 2)
      : rounded;
  return '$normalized ${normalized == '1' ? 'hour' : 'hours'}';
}

String formatMinutes(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hours = minutes / 60;
  final rounded = hours < 10
      ? hours.toStringAsFixed(1)
      : hours.round().toString();
  final normalized = rounded.endsWith('.0')
      ? rounded.substring(0, rounded.length - 2)
      : rounded;
  return '${normalized}h';
}

String formatRelativeDate(DateTime instant, DateTime asOf) {
  final difference = instant.difference(asOf);
  final days = difference.inDays;
  if (days.abs() < 1) {
    final hours = difference.inHours;
    if (hours.abs() < 1) return 'today';
    return hours < 0 ? '${hours.abs()}h ago' : 'in ${hours}h';
  }
  return days < 0 ? '${days.abs()}d ago' : 'in ${days}d';
}

String formatDayCount(int days) => '$days ${days == 1 ? 'day' : 'days'}';

/// Compact period label for the header button: "Oct 2026" for the current
/// month, otherwise the window's own label ("Last 7 days", "Aug – Oct 2026").
String shortWindowLabel(ReportWindow window, PeriodPreset preset) =>
    preset == PeriodPreset.thisMonth
    ? formatShortMonthYear(window.start)
    : window.label;
