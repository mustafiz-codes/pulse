import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'account.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.kind,
    this.industry,
    this.sizeBand,
  });

  final String id;
  final String name;
  final AccountKind kind;
  final String? industry;
  final String? sizeBand;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
}
