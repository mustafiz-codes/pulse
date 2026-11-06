// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Account _$AccountFromJson(Map<String, dynamic> json) => Account(
  id: json['id'] as String,
  name: json['name'] as String,
  kind: $enumDecode(_$AccountKindEnumMap, json['kind']),
  industry: json['industry'] as String?,
  sizeBand: json['size_band'] as String?,
);

const _$AccountKindEnumMap = {
  AccountKind.business: 'business',
  AccountKind.individual: 'individual',
};
