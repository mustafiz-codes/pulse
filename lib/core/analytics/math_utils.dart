double? median(Iterable<double> values) {
  final list = values.where((value) => value.isFinite).toList()..sort();
  if (list.isEmpty) return null;
  final middle = list.length ~/ 2;
  if (list.length.isOdd) return list[middle];
  return (list[middle - 1] + list[middle]) / 2;
}

double? mean(Iterable<double> values) {
  final list = values.where((value) => value.isFinite).toList();
  if (list.isEmpty) return null;
  return list.reduce((a, b) => a + b) / list.length;
}

double? safeRate(int numerator, int denominator) {
  if (denominator == 0) return null;
  return numerator / denominator;
}
