import 'package:intl/intl.dart';

final NumberFormat _currency0 = NumberFormat.currency(
  locale: 'en_GB',
  symbol: '£',
  decimalDigits: 0,
);

final NumberFormat _currency2 = NumberFormat.currency(
  locale: 'en_GB',
  symbol: '£',
  decimalDigits: 2,
);

final NumberFormat _compact = NumberFormat.compactCurrency(
  locale: 'en_GB',
  symbol: '£',
  decimalDigits: 1,
);

/// Formats integer minor units (pence) as GBP.
String formatMoneyMinor(int minor, {bool compact = false, bool pence = false}) {
  final value = minor / 100;
  if (compact && value.abs() >= 1000) {
    return _compact.format(value).replaceAll('.0', '');
  }
  return (pence ? _currency2 : _currency0).format(value);
}

String formatMoneyMinorSigned(
  int minor, {
  bool compact = false,
  bool pence = false,
}) {
  final formatted = formatMoneyMinor(
    minor.abs(),
    compact: compact,
    pence: pence,
  );
  if (minor > 0) return '+$formatted';
  if (minor < 0) return '−$formatted';
  return formatted;
}

String formatPercent(double fraction, {int decimals = 0}) =>
    '${(fraction * 100).toStringAsFixed(decimals)}%';

String formatPercentagePoints(double points, {int decimals = 0}) =>
    '${points >= 0 ? '+' : '−'}${points.abs().toStringAsFixed(decimals)} pts';

String formatNumber(int value) =>
    NumberFormat.decimalPattern('en_GB').format(value);

String formatCompactNumber(int value) =>
    NumberFormat.compact(locale: 'en_GB').format(value);
