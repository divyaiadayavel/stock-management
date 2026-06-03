class CartItem {
  final int productId;
  final String name;
  final double price;
  int qty;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.qty = 1,
  });

  double get total => price * qty;

  // --- ADD THIS TO PREVENT BUGS ---
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          productId == other.productId;

  @override
  int get hashCode => productId.hashCode;
}
