class CartItem {
  final int productId;
  final String name;
  final double price;
  final double sgst;
  final double cgst;
  final String? imagePath;

  int qty;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.sgst,
    required this.cgst,
    this.imagePath,
    this.qty = 1,
  });

  double get total => price * qty;

  double get tax => total * ((sgst + cgst) / 100);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem && productId == other.productId;

  @override
  int get hashCode => productId.hashCode;
}
