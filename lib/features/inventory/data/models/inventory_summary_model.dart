import '../../domain/entities/inventory_summary.dart';

class InventorySummaryModel extends InventorySummary {
  const InventorySummaryModel({
    required super.totalProducts,
    required super.totalStockUnits,
    required super.lowStockProducts,
    required super.outOfStockProducts,
    required super.expiringProducts,
    required super.expiredProducts,
    required super.inventoryValue,
    required super.stockInValue,
    required super.stockOutValue,
  });

  factory InventorySummaryModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return InventorySummaryModel(
      totalProducts:
          _toInt(map['total_products']),

      totalStockUnits:
          _toInt(map['total_units']),

      lowStockProducts:
          _toInt(map['low_stock_products']),

      outOfStockProducts:
          _toInt(map['out_of_stock_products']),

      expiringProducts:
          _toInt(map['expiring_products']),

      expiredProducts:
          _toInt(map['expired_products']),

      inventoryValue:
          _toDouble(map['inventory_value']),

      /*
       * These fields are not currently returned by the
       * inventory summary API as monetary values.
       *
       * Keep them at zero rather than incorrectly mapping
       * today's stock movement quantities into value fields.
       */
      stockInValue: 0.0,

      stockOutValue: 0.0,
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0.0;
  }
}