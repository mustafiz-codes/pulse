// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deal_stage_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DealStageEvent _$DealStageEventFromJson(Map<String, dynamic> json) =>
    DealStageEvent(
      id: json['id'] as String,
      dealId: json['deal_id'] as String,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      toStage: $enumDecode(_$DealStageEnumMap, json['to_stage']),
      source: json['source'] as String,
      fromStage: $enumDecodeNullable(_$DealStageEnumMap, json['from_stage']),
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
