class ReceiptItem {
  final String itemName;
  final int quantity;
  final double unitPrice;
  final double totalAmount;

  const ReceiptItem({
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
  });

  ReceiptItem copyWith({
    String? itemName,
    int? quantity,
    double? unitPrice,
    double? totalAmount,
  }) {
    return ReceiptItem(
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }
}