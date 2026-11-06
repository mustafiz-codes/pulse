// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lead.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Lead _$LeadFromJson(Map<String, dynamic> json) => Lead(
  id: json['id'] as String,
  accountId: json['account_id'] as String,
  ownerId: json['owner_id'] as String,
  productId: json['product_id'] as String,
  source: $enumDecode(_$LeadSourceEnumMap, json['source']),
  status: $enumDecode(_$LeadStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['created_at'] as String),
  firstContactedAt: json['first_contacted_at'] == null
      ? null
      : DateTime.parse(json['first_contacted_at'] as String),
  convertedDealId: json['converted_deal_id'] as String?,
  nextFollowUpAt: json['next_follow_up_at'] == null
      ? null
      : DateTime.parse(json['next_follow_up_at'] as String),
  lostReason: json['lost_reason'] as String?,
);

const _$LeadSourceEnumMap = {
  LeadSource.inbound: 'inbound',
  LeadSource.outbound: 'outbound',
  LeadSource.referral: 'referral',
  LeadSource.event: 'event',
  LeadSource.partner: 'partner',
  LeadSource.website: 'website',
};

const _$LeadStatusEnumMap = {
  LeadStatus.newLead: 'new',
  LeadStatus.contacted: 'contacted',
  LeadStatus.qualified: 'qualified',
  LeadStatus.converted: 'converted',
  LeadStatus.lost: 'lost',
  LeadStatus.unqualified: 'unqualified',
};
