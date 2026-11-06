// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SalesActivity _$SalesActivityFromJson(Map<String, dynamic> json) =>
    SalesActivity(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      type: $enumDecode(_$ActivityTypeEnumMap, json['type']),
      workCategory: $enumDecode(_$WorkCategoryEnumMap, json['work_category']),
      workSubcategory: json['work_subcategory'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      source: json['source'] as String,
      timeQuality: $enumDecode(_$TimeQualityEnumMap, json['time_quality']),
      leadId: json['lead_id'] as String?,
      dealId: json['deal_id'] as String?,
      accountId: json['account_id'] as String?,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      summary: json['summary'] as String?,
    );

const _$ActivityTypeEnumMap = {
  ActivityType.call: 'call',
  ActivityType.email: 'email',
  ActivityType.meeting: 'meeting',
  ActivityType.demo: 'demo',
  ActivityType.proposal: 'proposal',
  ActivityType.negotiation: 'negotiation',
  ActivityType.onboarding: 'onboarding',
  ActivityType.support: 'support',
  ActivityType.admin: 'admin',
  ActivityType.internalMeeting: 'internal_meeting',
  ActivityType.training: 'training',
  ActivityType.other: 'other',
};

const _$WorkCategoryEnumMap = {
  WorkCategory.sales: 'sales',
  WorkCategory.operations: 'operations',
  WorkCategory.other: 'other',
  WorkCategory.unknown: 'unknown',
};

const _$TimeQualityEnumMap = {
  TimeQuality.logged: 'logged',
  TimeQuality.estimated: 'estimated',
  TimeQuality.notRecorded: 'not_recorded',
};
