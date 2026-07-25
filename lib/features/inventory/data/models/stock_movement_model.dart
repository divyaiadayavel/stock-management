import '../../domain/entities/stock_movement.dart';

class StockMovementModel extends StockMovement {
  const StockMovementModel({
    super.id,
    required super.movementNumber,
    required super.productId,
    required super.productName,
    super.barcode,
    super.supplierId,
    super.supplierName,
    required super.movementType,
    required super.quantity,
    required super.stockBefore,
    required super.stockAfter,
    required super.unitCost,
    required super.totalAmount,
    super.referenceType,
    super.referenceNumber,
    super.remarks,
    super.createdBy,
    required super.createdAt,
  });

  factory StockMovementModel.fromMap(Map<String, dynamic> map) {
    return StockMovementModel(
      id: map["id"] != null
          ? int.tryParse(map["id"].toString())
          : null,

      movementNumber:
          map["movement_number"]?.toString() ??
          map["movement_no"]?.toString() ??
          "",

      productId:
          int.tryParse(map["product_id"].toString()) ?? 0,

      productName:
          map["product_name"]?.toString() ?? "",

      barcode:
          map["barcode"]?.toString(),

      supplierId: map["supplier_id"] != null
          ? int.tryParse(map["supplier_id"].toString())
          : null,

      supplierName:
          map["supplier_name"]?.toString() ?? "",

      movementType:
          map["movement_type"]?.toString() ?? "",

      quantity:
          int.tryParse(map["quantity"].toString()) ?? 0,

      stockBefore:
          int.tryParse(map["stock_before"].toString()) ?? 0,

      stockAfter:
          int.tryParse(map["stock_after"].toString()) ?? 0,

      unitCost:
          double.tryParse(map["unit_cost"].toString()) ?? 0,

      totalAmount:
          double.tryParse(map["total_amount"].toString()) ?? 0,

      referenceType:
          map["reference_type"]?.toString() ?? "",

      referenceNumber:
          map["reference_number"]?.toString() ?? "",

      remarks:
          map["remarks"]?.toString() ?? "",

      createdBy: map["created_by"] != null
          ? int.tryParse(map["created_by"].toString())
          : null,

      createdAt: DateTime.parse(
        map["created_at"]?.toString() ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) "id": id,
      "movement_number": movementNumber,
      "product_id": productId,
      "product_name": productName,
      "barcode": barcode,
      "supplier_id": supplierId,
      "supplier_name": supplierName,
      "movement_type": movementType,
      "quantity": quantity,
      "stock_before": stockBefore,
      "stock_after": stockAfter,
      "unit_cost": unitCost,
      "total_amount": totalAmount,
      "reference_type": referenceType,
      "reference_number": referenceNumber,
      "remarks": remarks,
      "created_by": createdBy,
      "created_at": createdAt.toIso8601String(),
    };
  }
}