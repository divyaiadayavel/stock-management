import '../../../../domain/entities/printers_hardware/receipt/receipt_item.dart';

class ReceiptItemModel extends ReceiptItem {
  const ReceiptItemModel({
    required super.itemName,
    required super.quantity,
    required super.unitPrice,
    required super.totalAmount,
  });

  factory ReceiptItemModel.fromEntity(ReceiptItem entity) {
    return ReceiptItemModel(
      itemName: entity.itemName,
      quantity: entity.quantity,
      unitPrice: entity.unitPrice,
      totalAmount: entity.totalAmount,
    );
  }

  factory ReceiptItemModel.fromJson(Map<String, dynamic> json) {
    return ReceiptItemModel(
      itemName: json['itemName']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
    };
  }

  @override
  ReceiptItemModel copyWith({
    String? itemName,
    int? quantity,
    double? unitPrice,
    double? totalAmount,
  }) {
    return ReceiptItemModel(
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }

  ReceiptItem toEntity() => this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptItemModel &&
          runtimeType == other.runtimeType &&
          itemName == other.itemName &&
          quantity == other.quantity &&
          unitPrice == other.unitPrice &&
          totalAmount == other.totalAmount;

  @override
  int get hashCode =>
      itemName.hashCode ^
      quantity.hashCode ^
      unitPrice.hashCode ^
      totalAmount.hashCode;
}