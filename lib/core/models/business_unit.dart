import 'package:json_annotation/json_annotation.dart';

part 'business_unit.g.dart';

/// One product sold by a business unit (e.g. "Visa" in Lawyer).
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class Product {
  const Product({required this.id, required this.label});

  final String id;
  final String label;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}

/// A business unit (Lawyer, Cloud, HR, Accountant, Global) and its products.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class BusinessUnit {
  const BusinessUnit({
    required this.id,
    required this.label,
    required this.products,
  });

  final String id;
  final String label;
  final List<Product> products;

  factory BusinessUnit.fromJson(Map<String, dynamic> json) =>
      _$BusinessUnitFromJson(json);
}
