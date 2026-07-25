import '../../domain/entities/inventory_summary.dart';

class InventorySummaryModel extends InventorySummary {
  const InventorySummaryModel({
    required super.totalProducts,
    required super.totalStockUnits,
    required super.lowStockProducts,
    required super.outOfStockProducts,
    required super.expiringProducts,
    required super.inventoryValue,
    required super.stockInValue,
    required super.stockOutValue,
  });

  factory InventorySummaryModel.fromMap(Map<String, dynamic> map) {
    return InventorySummaryModel(
      totalProducts:
          int.tryParse(map['total_products']?.toString() ?? '0') ?? 0,

      totalStockUnits:
          int.tryParse(map['total_stock_units']?.toString() ?? '0') ?? 0,

      lowStockProducts:
          int.tryParse(map['low_stock_products']?.toString() ?? '0') ?? 0,

      outOfStockProducts:
          int.tryParse(map['out_of_stock_products']?.toString() ?? '0') ?? 0,

      expiringProducts:
          int.tryParse(map['expiring_products']?.toString() ?? '0') ?? 0,

      inventoryValue:
          double.tryParse(map['inventory_value']?.toString() ?? '0') ?? 0,

      stockInValue:
          double.tryParse(map['stock_in_value']?.toString() ?? '0') ?? 0,

      stockOutValue:
          double.tryParse(map['stock_out_value']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_products': totalProducts,
      'total_stock_units': totalStockUnits,
      'low_stock_products': lowStockProducts,
      'out_of_stock_products': outOfStockProducts,
      'expiring_products': expiringProducts,
      'inventory_value': inventoryValue,
      'stock_in_value': stockInValue,
      'stock_out_value': stockOutValue,
    };
  }
}