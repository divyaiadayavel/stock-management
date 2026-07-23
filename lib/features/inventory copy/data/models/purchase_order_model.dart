import '../../domain/entities/purchase_order.dart';
import 'purchase_order_item_model.dart';

class PurchaseOrderModel extends PurchaseOrder {
  const PurchaseOrderModel({
    super.id,
    required super.poNumber,
    required super.supplierId,
    required super.supplierName,
    required super.status,
    required super.orderDate,
    super.expectedDeliveryDate,
    super.receivedDate,
    required super.subtotal,
    required super.taxAmount,
    required super.discountAmount,
    required super.grandTotal,
    required super.totalItems,
    required super.totalQuantity,
    super.remarks,
    super.createdBy,
    required super.createdAt,
    super.updatedAt,
    required super.items,
  });

  factory PurchaseOrderModel.fromMap(Map<String, dynamic> map) {
    return PurchaseOrderModel(
      id: map["id"] != null
          ? int.tryParse(map["id"].toString())
          : null,

      poNumber: map["po_number"]?.toString() ?? "",

      supplierId:
          int.tryParse(map["supplier_id"]?.toString() ?? "0") ?? 0,

      supplierName:
          map["supplier_name"]?.toString() ?? "",

      status:
          map["status"]?.toString() ?? "DRAFT",

      orderDate: DateTime.parse(
        map["order_date"]?.toString() ??
            DateTime.now().toIso8601String(),
      ),

      expectedDeliveryDate:
          map["expected_delivery_date"] != null
              ? DateTime.tryParse(
                  map["expected_delivery_date"].toString(),
                )
              : null,

      receivedDate:
          map["received_date"] != null
              ? DateTime.tryParse(
                  map["received_date"].toString(),
                )
              : null,

      subtotal:
          double.tryParse(
                map["subtotal"]?.toString() ?? "0",
              ) ??
              0,

      taxAmount:
          double.tryParse(
                map["tax_amount"]?.toString() ?? "0",
              ) ??
              0,

      discountAmount:
          double.tryParse(
                map["discount_amount"]?.toString() ?? "0",
              ) ??
              0,

      grandTotal:
          double.tryParse(
                map["grand_total"]?.toString() ?? "0",
              ) ??
              0,

      totalItems:
          int.tryParse(
                map["total_items"]?.toString() ?? "0",
              ) ??
              0,

      totalQuantity:
          int.tryParse(
                map["total_quantity"]?.toString() ?? "0",
              ) ??
              0,

      remarks:
          map["remarks"]?.toString() ?? "",

      createdBy: map["created_by"] != null
          ? int.tryParse(map["created_by"].toString())
          : null,

      createdAt: DateTime.parse(
        map["created_at"]?.toString() ??
            DateTime.now().toIso8601String(),
      ),

      updatedAt:
          map["updated_at"] != null
              ? DateTime.tryParse(
                  map["updated_at"].toString(),
                )
              : null,

      items: (map["items"] as List?)
              ?.map(
                (e) => PurchaseOrderItemModel.fromMap(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) "id": id,

      "po_number": poNumber,

      "supplier_id": supplierId,

      "status": status,

      "order_date": orderDate.toIso8601String(),

      "expected_delivery_date":
          expectedDeliveryDate?.toIso8601String(),

      "received_date":
          receivedDate?.toIso8601String(),

      "subtotal": subtotal,

      "tax_amount": taxAmount,

      "discount_amount": discountAmount,

      "grand_total": grandTotal,

      "total_items": totalItems,

      "total_quantity": totalQuantity,

      "remarks": remarks,

      "created_by": createdBy,

      "created_at": createdAt.toIso8601String(),

      "updated_at": updatedAt?.toIso8601String(),

      "items": items
          .map(
            (e) => (e as PurchaseOrderItemModel).toMap(),
          )
          .toList(),
    };
  }
}