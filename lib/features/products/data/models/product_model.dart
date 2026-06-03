class Product {
  int? id;
  String name;
  String category;
  String hsnCode;
  double purchasePrice;
  double sellingPrice;
  int quantity;
  String unit;
  String description;
  String imagePath;

  Product({
    this.id,
    required this.name,
    required this.category,
    required this.hsnCode,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.quantity,
    required this.unit,
    required this.description,
    required this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'hsnCode': hsnCode,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'quantity': quantity,
      'unit': unit,
      'description': description,
      'imagePath': imagePath,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      hsnCode: map['hsnCode'],
      purchasePrice: map['purchasePrice'],
      sellingPrice: map['sellingPrice'],
      quantity: map['quantity'],
      unit: map['unit'],
      description: map['description'],
      imagePath: map['imagePath'],
    );
  }
}
