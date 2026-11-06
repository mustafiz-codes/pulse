import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'insight_scenario.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class InsightScenario {
  const InsightScenario({
    required this.id,
    required this.label,
    required this.description,
    required this.route,
    this.period,
    this.unitId,
    this.ownerId,
    this.stage,
    this.focusDealId,
  });

  final String id;
  final String label;
  final String description;
  final String route;
  final String? period;
  final String? unitId;
  final String? ownerId;
  final DealStage? stage;
  final String? focusDealId;

  factory InsightScenario.fromJson(Map<String, dynamic> json) =>
      _$InsightScenarioFromJson(json);
}
