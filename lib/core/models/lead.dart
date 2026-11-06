import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'lead.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Lead {
  const Lead({
    required this.id,
    required this.accountId,
    required this.ownerId,
    required this.productId,
    required this.source,
    required this.status,
    required this.createdAt,
    this.firstContactedAt,
    this.convertedDealId,
    this.nextFollowUpAt,
    this.lostReason,
  });

  final String id;
  final String accountId;
  final String ownerId;

  /// Product the lead is interested in; its unit comes from the catalogue.
  final String productId;
  final LeadSource source;
  final LeadStatus status;
  final DateTime createdAt;
  final DateTime? firstContactedAt;
  final String? convertedDealId;
  final DateTime? nextFollowUpAt;
  final String? lostReason;

  bool get isOpen =>
      status == LeadStatus.newLead ||
      status == LeadStatus.contacted ||
      status == LeadStatus.qualified;

  factory Lead.fromJson(Map<String, dynamic> json) => _$LeadFromJson(json);
}
