// lib/features/sales/data/models/cart_item_model.dart
class CartItem {
  final int productId;
  final String name;
  final String category;
  final double price;      // unit_price
  final double sgst;
  final double cgst;
  final double discount;   // discount percent (stored as percent, e.g., 10 for 10%)
  final String? imagePath;

  int qty;

  CartItem({
    required this.productId,
    required this.name,
    required this.category,
    required this.price,
    required this.sgst,
    required this.cgst,
    required this.discount,
    this.imagePath,
    this.qty = 1,
  });

  double get subtotal => price * qty;
  double get discountAmount => subtotal * (discount / 100);
  double get total => subtotal - discountAmount;
  double get tax => total * ((sgst + cgst) / 100);

  Map<String, dynamic> toMap() {
    return {
      "product_id": productId,
      "product_name": name,
      "quantity": qty.toDouble(),
      "unit_price": price,
      "discount": discountAmount,   // total discount amount for this line item
      "tax": tax,                  // total tax for this line item
      "total": total,              // line total after discount (before tax? actually total before tax? adjust as needed)
    };
    // Note: The database 'sale_items' has 'discount' and 'tax' as amounts,
    // not percentages. We store the computed amounts.
  }

factory CartItem.fromMap(Map<String, dynamic> map) {
  return CartItem(
    productId: int.parse(map["product_id"].toString()),
    name: map["product_name"]?.toString() ??
        map["name"]?.toString() ??
        "",
    category: map["category"]?.toString() ?? "General",
    price: double.parse(
      (map["unit_price"] ?? map["price"]).toString(),
    ),
    qty: int.parse(
      (map["quantity"] ?? map["qty"]).toString(),
    ),
    sgst: double.tryParse(
          (map["sgst"] ?? 0).toString(),
        ) ??
        0,
    cgst: double.tryParse(
          (map["cgst"] ?? 0).toString(),
        ) ??
        0,
    discount: double.tryParse(
          (map["discount"] ?? 0).toString(),
        ) ??
        0,
    imagePath: map["imagePath"]?.toString(),
  );
}
}