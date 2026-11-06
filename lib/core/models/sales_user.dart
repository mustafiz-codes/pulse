import 'package:json_annotation/json_annotation.dart';

part 'sales_user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class SalesUser {
  const SalesUser({
    required this.id,
    required this.displayName,
    required this.jobRole,
    required this.homeUnitId,
    required this.active,
    this.avatarAsset,
  });

  final String id;
  final String displayName;
  final String jobRole;

  /// The business unit this rep mostly sells for.
  final String homeUnitId;
  final bool active;
  final String? avatarAsset;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  factory SalesUser.fromJson(Map<String, dynamic> json) =>
      _$SalesUserFromJson(json);
}
