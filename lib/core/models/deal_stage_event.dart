import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'deal_stage_event.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class DealStageEvent {
  const DealStageEvent({
    required this.id,
    required this.dealId,
    required this.occurredAt,
    required this.toStage,
    required this.source,
    this.fromStage,
  });

  final String id;
  final String dealId;
  final DateTime occurredAt;
  final DealStage? fromStage;
  final DealStage toStage;
  final String source;

  factory DealStageEvent.fromJson(Map<String, dynamic> json) =>
      _$DealStageEventFromJson(json);
}
