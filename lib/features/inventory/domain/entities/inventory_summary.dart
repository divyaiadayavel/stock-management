import 'package:equatable/equatable.dart';

class InventorySummary extends Equatable {
  final int totalProducts;
  final int totalStockUnits;

  final int lowStockProducts;
  final int outOfStockProducts;

  final int expiringProducts;
  final int expiredProducts;

  final double inventoryValue;

  final double stockInValue;
  final double stockOutValue;

  const InventorySummary({
    required this.totalProducts,
    required this.totalStockUnits,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.expiringProducts,
    required this.expiredProducts,
    required this.inventoryValue,
    required this.stockInValue,
    required this.stockOutValue,
  });

  @override
  List<Object?> get props => [
        totalProducts,
        totalStockUnits,
        lowStockProducts,
        outOfStockProducts,
        expiringProducts,
        expiredProducts,
        inventoryValue,
        stockInValue,
        stockOutValue,
      ];
}