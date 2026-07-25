import '../../../products/data/models/product_model.dart';
import '../../domain/entities/purchase_order_item.dart';

class PurchaseOrderItemModel extends PurchaseOrderItem {
  const PurchaseOrderItemModel({
    super.id,
    super.purchaseOrderId,
    required super.product,
    required super.orderedQuantity,
    super.receivedQuantity,
    required super.unitPrice,
    super.discountPercentage,
    super.taxPercentage,
    super.status,
  });

  factory PurchaseOrderItemModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return PurchaseOrderItemModel(
      id: map["id"] != null
          ? int.tryParse(map["id"].toString())
          : null,

      purchaseOrderId: map["purchase_order_id"] != null
          ? int.tryParse(map["purchase_order_id"].toString())
          : null,

      product: Product.fromMap(map),

      orderedQuantity:
          int.tryParse(map["ordered_quantity"].toString()) ?? 0,

      receivedQuantity:
          int.tryParse(
                map["received_quantity"]?.toString() ?? "0",
              ) ??
              0,

      unitPrice:
          double.tryParse(
                map["unit_price"]?.toString() ?? "0",
              ) ??
              0,

      discountPercentage:
          double.tryParse(
                map["discount_percentage"]?.toString() ?? "0",
              ) ??
              0,

      taxPercentage:
          double.tryParse(
                map["tax_percentage"]?.toString() ?? "0",
              ) ??
              0,

      status:
          map["status"]?.toString() ?? "PENDING",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) "id": id,

      "purchase_order_id": purchaseOrderId,

      "product_id": product.id,

      "ordered_quantity": orderedQuantity,

      "received_quantity": receivedQuantity,

      "unit_price": unitPrice,

      "discount_percentage": discountPercentage,

      "tax_percentage": taxPercentage,

      "status": status,
    };
  }
}