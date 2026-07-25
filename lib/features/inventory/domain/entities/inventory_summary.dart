class InventorySummary {
  final int totalProducts;
  final int totalStockUnits;
  final int lowStockProducts;
  final int outOfStockProducts;
  final int expiringProducts;

  final double inventoryValue;
  final double stockInValue;
  final double stockOutValue;

  const InventorySummary({
    required this.totalProducts,
    required this.totalStockUnits,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.expiringProducts,
    required this.inventoryValue,
    required this.stockInValue,
    required this.stockOutValue,
  });

  InventorySummary copyWith({
    int? totalProducts,
    int? totalStockUnits,
    int? lowStockProducts,
    int? outOfStockProducts,
    int? expiringProducts,
    double? inventoryValue,
    double? stockInValue,
    double? stockOutValue,
  }) {
    return InventorySummary(
      totalProducts: totalProducts ?? this.totalProducts,
      totalStockUnits: totalStockUnits ?? this.totalStockUnits,
      lowStockProducts: lowStockProducts ?? this.lowStockProducts,
      outOfStockProducts:
          outOfStockProducts ?? this.outOfStockProducts,
      expiringProducts:
          expiringProducts ?? this.expiringProducts,
      inventoryValue:
          inventoryValue ?? this.inventoryValue,
      stockInValue:
          stockInValue ?? this.stockInValue,
      stockOutValue:
          stockOutValue ?? this.stockOutValue,
    );
  }
}