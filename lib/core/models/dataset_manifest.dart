import 'package:json_annotation/json_annotation.dart';

part 'dataset_manifest.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class DatasetManifest {
  const DatasetManifest({
    required this.schemaVersion,
    required this.datasetId,
    required this.datasetLabel,
    required this.dataKind,
    required this.currency,
    required this.timezone,
    required this.asOf,
    required this.periodStart,
    required this.periodEnd,
    required this.sourceDescription,
  });

  final String schemaVersion;
  final String datasetId;
  final String datasetLabel;
  final String dataKind;
  final String currency;
  final String timezone;
  final DateTime asOf;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String sourceDescription;

  factory DatasetManifest.fromJson(Map<String, dynamic> json) =>
      _$DatasetManifestFromJson(json);
}
