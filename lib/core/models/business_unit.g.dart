// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_unit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) =>
    Product(id: json['id'] as String, label: json['label'] as String);

BusinessUnit _$BusinessUnitFromJson(Map<String, dynamic> json) => BusinessUnit(
  id: json['id'] as String,
  label: json['label'] as String,
  products: (json['products'] as List<dynamic>)
      .map((e) => Product.fromJson(e as Map<String, dynamic>))
      .toList(),
);
