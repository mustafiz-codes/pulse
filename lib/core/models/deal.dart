import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'deal.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Deal {
  const Deal({
    required this.id,
    required this.accountId,
    required this.ownerId,
    required this.productId,
    required this.title,
    required this.valueMinor,
    required this.currency,
    required this.stage,
    required this.createdAt,
    required this.outcome,
    this.leadId,
    this.closedAt,
    this.probability,
    this.lastActivityAt,
  });

  final String id;
  final String? leadId;
  final String accountId;
  final String ownerId;

  /// Product sold; always the same as the linked lead's product.
  final String productId;
  final String title;
  final int valueMinor;
  final String currency;
  final DealStage stage;
  final DateTime createdAt;
  final DateTime? closedAt;
  final DealOutcome outcome;
  final double? probability;
  final DateTime? lastActivityAt;

  bool get isOpen => outcome == DealOutcome.open;
  bool get isWon => outcome == DealOutcome.won;
  bool get isLost => outcome == DealOutcome.lost;

  factory Deal.fromJson(Map<String, dynamic> json) => _$DealFromJson(json);
}
