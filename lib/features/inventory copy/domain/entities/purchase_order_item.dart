import '../../../products/data/models/product_model.dart';

class PurchaseOrderItem {
  final int? id;

  /// Parent Purchase Order ID
  final int? purchaseOrderId;

  /// Product
  final Product product;

  /// Ordered Quantity
  final int orderedQuantity;

  /// Received Quantity
  final int receivedQuantity;

  /// Purchase Price
  final double unitPrice;

  /// Discount %
  final double discountPercentage;

  /// GST %
  final double taxPercentage;

  /// Status
  /// PENDING | PARTIAL | RECEIVED
  final String status;

  const PurchaseOrderItem({
    this.id,
    this.purchaseOrderId,
    required this.product,
    required this.orderedQuantity,
    this.receivedQuantity = 0,
    required this.unitPrice,
    this.discountPercentage = 0,
    this.taxPercentage = 0,
    this.status = "PENDING",
  });

  /// Line Subtotal
  double get subtotal => orderedQuantity * unitPrice;

  /// Discount Amount
  double get discountAmount =>
      subtotal * (discountPercentage / 100);

  /// Taxable Amount
  double get taxableAmount =>
      subtotal - discountAmount;

  /// GST Amount
  double get taxAmount =>
      taxableAmount * (taxPercentage / 100);

  /// Line Total
  double get total =>
      taxableAmount + taxAmount;

  /// Pending Quantity
  int get pendingQuantity =>
      orderedQuantity - receivedQuantity;

  /// Fully Received?
  bool get isCompleted =>
      receivedQuantity >= orderedQuantity;

  PurchaseOrderItem copyWith({
    int? id,
    int? purchaseOrderId,
    Product? product,
    int? orderedQuantity,
    int? receivedQuantity,
    double? unitPrice,
    double? discountPercentage,
    double? taxPercentage,
    String? status,
  }) {
    return PurchaseOrderItem(
      id: id ?? this.id,
      purchaseOrderId:
          purchaseOrderId ?? this.purchaseOrderId,
      product: product ?? this.product,
      orderedQuantity:
          orderedQuantity ?? this.orderedQuantity,
      receivedQuantity:
          receivedQuantity ?? this.receivedQuantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercentage:
          discountPercentage ?? this.discountPercentage,
      taxPercentage:
          taxPercentage ?? this.taxPercentage,
      status: status ?? this.status,
    );
  }
}