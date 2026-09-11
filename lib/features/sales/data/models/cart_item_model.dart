// lib/features/sales/data/models/cart_item_model.dart
class CartItem {
  final int productId;
  final String name;
  final String category;
  final double price;      // unit_price
  final double sgst;       // percent — live-cart rate pulled from the product
  final double cgst;       // percent — live-cart rate pulled from the product
  final double discount;   // discount percent (stored as percent, e.g., 10 for 10%)
  final String? imagePath;

  // ── Reload-safe amounts ──────────────────────────────────────────
  // The server persists the final computed discount/tax AMOUNTS for a sale
  // line, not the percentages above (percentages can change on the product
  // after the sale). When an invoice is loaded back via fromMap, these are
  // populated from what the server actually saved, and the getters below
  // prefer them over recomputing from `discount`/`sgst`/`cgst`. Fresh cart
  // items (built in billing_provider.dart while creating a bill) leave these
  // null, so they keep computing live from the percentages as before.
  final double? savedDiscountAmount;
  final double? savedTaxAmount;

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
    this.savedDiscountAmount,
    this.savedTaxAmount,
  });

  double get subtotal => price * qty;
  double get discountAmount =>
      savedDiscountAmount ?? (subtotal * (discount / 100));
  double get total => subtotal - discountAmount;
  double get tax => savedTaxAmount ?? (total * ((sgst + cgst) / 100));

  // Even split convention (matches the invoice-level CGST/SGST split already
  // used for the printed summary) — used to show a per-item rate breakdown
  // when the server hasn't stored separate CGST/SGST rates for the line.
  double get cgstAmount => tax / 2;
  double get sgstAmount => tax / 2;

  Map<String, dynamic> toMap() {
    return {
      "product_id": productId,
      "product_name": name,
      "quantity": qty.toDouble(),
      "unit_price": price,
      "discount": discountAmount,   // total discount amount for this line item
      "discount_percent": discount, // rate at time of sale, for future reference
      "sgst_percent": sgst,
      "cgst_percent": cgst,
      "tax": tax,                  // total tax for this line item
      "total": total,              // line total after discount (before tax? actually total before tax? adjust as needed)
    };
    // Note: The database 'sale_items' has 'discount' and 'tax' as amounts,
    // not percentages. We store the computed amounts, plus the rate percents
    // for reference (a backend that persists them can return richer detail).
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
          (map["sgst_percent"] ?? map["sgst"] ?? 0).toString(),
        ) ??
        0,
    cgst: double.tryParse(
          (map["cgst_percent"] ?? map["cgst"] ?? 0).toString(),
        ) ??
        0,
    discount: double.tryParse(
          (map["discount_percent"] ?? 0).toString(),
        ) ??
        0,
    imagePath: map["imagePath"]?.toString(),
    // Prefer the amounts the server actually has on file for this line.
    savedDiscountAmount: map["discount"] != null
        ? double.tryParse(map["discount"].toString())
        : null,
    savedTaxAmount:
        map["tax"] != null ? double.tryParse(map["tax"].toString()) : null,
  );
}
}