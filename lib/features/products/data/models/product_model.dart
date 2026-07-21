class Product {
  int? id;
  String name;
  String category;
  int? categoryId;        // new
  String hsnCode;
  double purchasePrice;
  double sellingPrice;
  int quantity;
  String unit;
  int? unitId;            // new
  String description;
  String imagePath;
  String barcode;
  double sgst;
  double cgst;
  double discount;
  String expiryDate;
  String supplier;
  int? supplierId;
  int lsl;
  String status;

  Product({
    this.id,
    required this.name,
    required this.category,
    this.categoryId,
    required this.hsnCode,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.quantity,
    required this.unit,
    this.unitId,
    required this.description,
    required this.imagePath,
    this.barcode = "",
    this.sgst = 0.0,
    this.cgst = 0.0,
    this.discount = 0.0,
    this.expiryDate = "",
    this.supplierId,
    required this.supplier,
    this.lsl = 10,
    this.status = "ACTIVE",
  });

Map<String, dynamic> toMap() {
  return {
    if (id != null) 'id': id,
    'barcode': barcode,
    'product_name': name,
    'category_id': (categoryId != null && categoryId! > 0) ? categoryId : 1,   // always an int
    'unit_id': (unitId != null && unitId! > 0) ? unitId : 1,         // always an int
    'purchase_price': purchasePrice,
    'selling_price': sellingPrice,
    'tax_percentage': sgst + cgst,
    'discount_percentage': discount,
    'current_stock': quantity,
    'minimum_stock': lsl,
    'reorder_level': lsl,
    'description': description,
    'hsn_code': hsnCode,
    'expiry_date': expiryDate,
    'supplier_id': supplierId,
    'supplier': supplier,
    'status': status,
  };
}

  factory Product.fromMap(Map<String, dynamic> map) {
    String resolvedImage = map['image']?.toString() ?? map['image_path']?.toString() ?? '';
    if (resolvedImage.isNotEmpty && !resolvedImage.startsWith('http') && !resolvedImage.startsWith('/')) {
      resolvedImage = 'https://nonredemptive-gyrational-pauletta.ngrok-free.dev/public_html/' + resolvedImage;
    }

    return Product(
      id: map['id'] != null ? int.tryParse(map['id'].toString()) : null,
      name: map['product_name']?.toString() ?? map['name']?.toString() ?? '',
      category: map['category_name']?.toString() ?? map['category']?.toString() ?? 'General',
      categoryId: map['category_id'] != null ? int.tryParse(map['category_id'].toString()) : null,
      hsnCode: map['hsn_code']?.toString() ?? map['hsnCode']?.toString() ?? '',
      purchasePrice: double.tryParse(map['purchase_price']?.toString() ?? map['purchasePrice']?.toString() ?? '0.0') ?? 0.0,
      sellingPrice: double.tryParse(map['selling_price']?.toString() ?? map['sellingPrice']?.toString() ?? '0.0') ?? 0.0,
      quantity: double.tryParse(map['current_stock']?.toString() ?? map['quantity']?.toString() ?? '0')?.toInt() ?? 0,
      unit: map['unit_name']?.toString() ?? map['unit']?.toString() ?? 'piece',
      unitId: map['unit_id'] != null ? int.tryParse(map['unit_id'].toString()) : null,
      description: map['description']?.toString() ?? '',
      imagePath: resolvedImage,
      barcode: map['barcode']?.toString() ?? '',
      sgst: double.tryParse(map['tax_percentage']?.toString() ?? '0.0') ?? 0.0,
      cgst: 0.0,
      discount: double.tryParse(map['discount_percentage']?.toString() ?? '0.0') ?? 0.0,
      expiryDate: map['expiry_date']?.toString() ?? '',
      supplier: map['supplier_name']?.toString() ?? map['supplier']?.toString() ?? '',
      supplierId: map['supplier_id'] != null
    ? int.tryParse(map['supplier_id'].toString())
    : null,
      lsl: double.tryParse(map['minimum_stock']?.toString() ?? map['lsl']?.toString() ?? '10')?.toInt() ?? 10,
      status: map['status']?.toString() ?? 'ACTIVE',
    );
  }
}