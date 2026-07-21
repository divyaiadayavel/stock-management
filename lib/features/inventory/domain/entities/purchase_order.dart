import 'purchase_order_item.dart';

class PurchaseOrder {
  final int? id;

  /// PO Number (PO000001)
  final String poNumber;

  /// Supplier
  final int supplierId;
  final String supplierName;

  /// DRAFT | SENT | PARTIAL | RECEIVED | CANCELLED
  final String status;

  /// Dates
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final DateTime? receivedDate;

  /// Totals
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double grandTotal;

  /// Total ordered items
  final int totalItems;

  /// Total ordered quantity
  final int totalQuantity;

  /// Notes
  final String remarks;

  /// Audit
  final int? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Purchase Order Items
  final List<PurchaseOrderItem> items;

  const PurchaseOrder({
    this.id,
    required this.poNumber,
    required this.supplierId,
    required this.supplierName,
    this.status = "DRAFT",
    required this.orderDate,
    this.expectedDeliveryDate,
    this.receivedDate,
    this.subtotal = 0,
    this.taxAmount = 0,
    this.discountAmount = 0,
    this.grandTotal = 0,
    this.totalItems = 0,
    this.totalQuantity = 0,
    this.remarks = "",
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  PurchaseOrder copyWith({
    int? id,
    String? poNumber,
    int? supplierId,
    String? supplierName,
    String? status,
    DateTime? orderDate,
    DateTime? expectedDeliveryDate,
    DateTime? receivedDate,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? grandTotal,
    int? totalItems,
    int? totalQuantity,
    String? remarks,
    int? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PurchaseOrderItem>? items,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      poNumber: poNumber ?? this.poNumber,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      status: status ?? this.status,
      orderDate: orderDate ?? this.orderDate,
      expectedDeliveryDate:
          expectedDeliveryDate ?? this.expectedDeliveryDate,
      receivedDate: receivedDate ?? this.receivedDate,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      totalItems: totalItems ?? this.totalItems,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      remarks: remarks ?? this.remarks,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}