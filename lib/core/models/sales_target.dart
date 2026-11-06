import 'package:json_annotation/json_annotation.dart';

part 'sales_target.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class SalesTarget {
  const SalesTarget({
    required this.ownerId,
    required this.periodMonth,
    required this.currency,
    required this.wonValueTargetMinor,
  });

  final String ownerId;
  final String periodMonth;
  final String currency;
  final int wonValueTargetMinor;

  factory SalesTarget.fromJson(Map<String, dynamic> json) =>
      _$SalesTargetFromJson(json);
}
