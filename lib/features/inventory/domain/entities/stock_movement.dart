class StockMovement {
  final int? id;

  /// Movement Number (SM000001)
  final String movementNumber;

  /// Product Information
  final int productId;
  final String productName;
  final String? barcode;

  /// Supplier (Optional)
  final int? supplierId;
  final String supplierName;

  /// STOCK_IN | STOCK_OUT | SALE | PURCHASE | RETURN | DAMAGE | ADJUSTMENT
  final String movementType;

  /// Quantity Moved
  final int quantity;

  /// Stock Before Transaction
  final int stockBefore;

  /// Stock After Transaction
  final int stockAfter;

  /// Cost Price at the Time of Movement
  final double unitCost;

  /// Total Movement Value
  final double totalAmount;

  /// Purchase Order / Invoice / Manual
  final String referenceType;

  /// PO Number / Invoice Number / Manual Ref
  final String referenceNumber;

  /// User Notes
  final String remarks;

  /// User who performed the transaction
  final int? createdBy;

  /// Date & Time
  final DateTime createdAt;

  const StockMovement({
    this.id,
    required this.movementNumber,
    required this.productId,
    required this.productName,
    this.barcode,
    this.supplierId,
    this.supplierName = "",
    required this.movementType,
    required this.quantity,
    required this.stockBefore,
    required this.stockAfter,
    required this.unitCost,
    required this.totalAmount,
    this.referenceType = "",
    this.referenceNumber = "",
    this.remarks = "",
    this.createdBy,
    required this.createdAt,
  });

  StockMovement copyWith({
    int? id,
    String? movementNumber,
    int? productId,
    String? productName,
    String? barcode,
    int? supplierId,
    String? supplierName,
    String? movementType,
    int? quantity,
    int? stockBefore,
    int? stockAfter,
    double? unitCost,
    double? totalAmount,
    String? referenceType,
    String? referenceNumber,
    String? remarks,
    int? createdBy,
    DateTime? createdAt,
  }) {
    return StockMovement(
      id: id ?? this.id,
      movementNumber: movementNumber ?? this.movementNumber,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      barcode: barcode ?? this.barcode,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      movementType: movementType ?? this.movementType,
      quantity: quantity ?? this.quantity,
      stockBefore: stockBefore ?? this.stockBefore,
      stockAfter: stockAfter ?? this.stockAfter,
      unitCost: unitCost ?? this.unitCost,
      totalAmount: totalAmount ?? this.totalAmount,
      referenceType: referenceType ?? this.referenceType,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      remarks: remarks ?? this.remarks,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}