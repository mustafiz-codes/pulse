import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'sales_activity.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class SalesActivity {
  const SalesActivity({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.workCategory,
    required this.workSubcategory,
    required this.startedAt,
    required this.source,
    required this.timeQuality,
    this.leadId,
    this.dealId,
    this.accountId,
    this.durationMinutes,
    this.summary,
  });

  final String id;
  final String ownerId;
  final String? leadId;
  final String? dealId;
  final String? accountId;
  final ActivityType type;
  final WorkCategory workCategory;
  final String workSubcategory;
  final DateTime startedAt;
  final int? durationMinutes;
  final String? summary;
  final String source;
  final TimeQuality timeQuality;

  bool get hasValidLoggedDuration =>
      timeQuality == TimeQuality.logged && durationMinutes != null;

  bool get hasEstimatedDuration =>
      timeQuality == TimeQuality.estimated && durationMinutes != null;

  factory SalesActivity.fromJson(Map<String, dynamic> json) =>
      _$SalesActivityFromJson(json);
}
