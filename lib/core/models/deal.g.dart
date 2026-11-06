// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Deal _$DealFromJson(Map<String, dynamic> json) => Deal(
  id: json['id'] as String,
  accountId: json['account_id'] as String,
  ownerId: json['owner_id'] as String,
  productId: json['product_id'] as String,
  title: json['title'] as String,
  valueMinor: (json['value_minor'] as num).toInt(),
  currency: json['currency'] as String,
  stage: $enumDecode(_$DealStageEnumMap, json['stage']),
  createdAt: DateTime.parse(json['created_at'] as String),
  outcome: $enumDecode(_$DealOutcomeEnumMap, json['outcome']),
  leadId: json['lead_id'] as String?,
  closedAt: json['closed_at'] == null
      ? null
      : DateTime.parse(json['closed_at'] as String),
  probability: (json['probability'] as num?)?.toDouble(),
  lastActivityAt: json['last_activity_at'] == null
      ? null
      : DateTime.parse(json['last_activity_at'] as String),
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

const _$DealOutcomeEnumMap = {
  DealOutcome.open: 'open',
  DealOutcome.won: 'won',
  DealOutcome.lost: 'lost',
};
