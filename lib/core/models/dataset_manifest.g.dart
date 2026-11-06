// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dataset_manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DatasetManifest _$DatasetManifestFromJson(Map<String, dynamic> json) =>
    DatasetManifest(
      schemaVersion: json['schema_version'] as String,
      datasetId: json['dataset_id'] as String,
      datasetLabel: json['dataset_label'] as String,
      dataKind: json['data_kind'] as String,
      currency: json['currency'] as String,
      timezone: json['timezone'] as String,
      asOf: DateTime.parse(json['as_of'] as String),
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      sourceDescription: json['source_description'] as String,
    );
