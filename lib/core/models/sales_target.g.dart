// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_target.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SalesTarget _$SalesTargetFromJson(Map<String, dynamic> json) => SalesTarget(
  ownerId: json['owner_id'] as String,
  periodMonth: json['period_month'] as String,
  currency: json['currency'] as String,
  wonValueTargetMinor: (json['won_value_target_minor'] as num).toInt(),
);
