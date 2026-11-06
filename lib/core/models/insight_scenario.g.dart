// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insight_scenario.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InsightScenario _$InsightScenarioFromJson(Map<String, dynamic> json) =>
    InsightScenario(
      id: json['id'] as String,
      label: json['label'] as String,
      description: json['description'] as String,
      route: json['route'] as String,
      period: json['period'] as String?,
      unitId: json['unit_id'] as String?,
      ownerId: json['owner_id'] as String?,
      stage: $enumDecodeNullable(_$DealStageEnumMap, json['stage']),
      focusDealId: json['focus_deal_id'] as String?,
    );

const _$DealStageEnumMap = {
  DealStage.newStage: 'new',
  DealStage.qualified: 'qualified',
  DealStage.discovery: 'discovery',
  DealStage.proposal: 'proposal',
  DealStage.negotiation: 'negotiation',
  DealStage.won: 'won',
  DealStage.lost: 'lost',
};
