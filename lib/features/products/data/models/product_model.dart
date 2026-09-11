import '../../../../core/network/api_config.dart';

class Product {
  int? id;

  String name;
  String category;
  int? categoryId;

  String hsnCode;

  double purchasePrice;
  double sellingPrice;

  int quantity;

  String unit;
  int? unitId;

  String description;
  String imagePath;
  String barcode;

  double sgst;
  double cgst;
  double discount;

  /// Product expiry date.
  ///
  /// Expected API field:
  /// expiry_date
  ///
  /// Stored as a String because the product API uses a
  /// MySQL DATE value such as:
  ///
  /// 2026-08-25
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

    this.barcode = '',

    this.sgst = 0.0,
    this.cgst = 0.0,
    this.discount = 0.0,

    this.expiryDate = '',

    required this.supplier,
    this.supplierId,

    this.lsl = 10,

    this.status = 'ACTIVE',
  });

  // ============================================================
  // API REQUEST MAPPING
  // ============================================================

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      if (id != null)
        'id': id,

      'barcode': barcode.trim(),

      'product_name': name.trim(),

      'purchase_price': purchasePrice,

      'selling_price': sellingPrice,

      'tax_percentage': sgst + cgst,

      'discount_percentage': discount,

      'current_stock': quantity,

      'minimum_stock': lsl,

      'reorder_level': lsl,

      'description': description.trim(),

      'hsn_code': hsnCode.trim(),

      'expiry_date': expiryDate.trim(),

      'supplier': supplier.trim(),

      'status': status.trim().isEmpty
          ? 'ACTIVE'
          : status.trim(),
    };

    if (categoryId != null) {
      map['category_id'] = categoryId;
    }

    if (unitId != null) {
      map['unit_id'] = unitId;
    }

    if (supplierId != null) {
      map['supplier_id'] = supplierId;
    }

    return map;
  }

  // ============================================================
  // API RESPONSE MAPPING
  // ============================================================

  factory Product.fromMap(
    Map<String, dynamic> map,
  ) {
    // ----------------------------------------------------------
    // IMAGE
    // ----------------------------------------------------------

    String resolvedImage =
        map['image']?.toString() ??
        map['image_path']?.toString() ??
        '';

    resolvedImage = resolvedImage.trim();

if (resolvedImage.isNotEmpty &&
    !resolvedImage.startsWith('http://') &&
    !resolvedImage.startsWith('https://') &&
    !resolvedImage.startsWith('/')) {
  resolvedImage =
      '${ApiConfig.baseUrl}/$resolvedImage';
}
    // ----------------------------------------------------------
    // EXPIRY DATE
    // ----------------------------------------------------------
    //
    // Backend inventory.php returns:
    //
    // "expiry_date": "2026-08-25"
    //
    // Keep the original value as a String.
    //
    // IMPORTANT:
    // We intentionally DO NOT calculate expiring/expired here.
    //
    // The backend handles:
    //
    // expiring:
    // expiry_date >= CURDATE()
    // AND expiry_date <= CURDATE() + 30 days
    //
    // expired:
    // expiry_date < CURDATE()
    //
    // This prevents Flutter and PHP from having two different
    // definitions of expiry status.
    // ----------------------------------------------------------

    final resolvedExpiryDate =
        map['expiry_date']
                ?.toString()
                .trim() ??
            '';

    // ----------------------------------------------------------
    // PRODUCT
    // ----------------------------------------------------------

    return Product(
      id: map['id'] != null
          ? int.tryParse(
              map['id'].toString(),
            )
          : null,

      name:
          map['product_name']
                  ?.toString()
                  .trim() ??
              map['name']
                  ?.toString()
                  .trim() ??
              '',

      category:
          map['category_name']
                  ?.toString()
                  .trim() ??
              map['category']
                  ?.toString()
                  .trim() ??
              'General',

      categoryId:
          map['category_id'] != null
              ? int.tryParse(
                  map['category_id'].toString(),
                )
              : null,

      hsnCode:
          map['hsn_code']
                  ?.toString()
                  .trim() ??
              map['hsnCode']
                  ?.toString()
                  .trim() ??
              '',

      purchasePrice:
          double.tryParse(
                map['purchase_price']
                        ?.toString() ??
                    map['purchasePrice']
                        ?.toString() ??
                    '0.0',
              ) ??
              0.0,

      sellingPrice:
          double.tryParse(
                map['selling_price']
                        ?.toString() ??
                    map['sellingPrice']
                        ?.toString() ??
                    '0.0',
              ) ??
              0.0,

      quantity:
          double.tryParse(
                map['current_stock']
                        ?.toString() ??
                    map['quantity']
                        ?.toString() ??
                    '0',
              )
              ?.toInt() ??
          0,

      unit:
          map['unit_name']
                  ?.toString()
                  .trim() ??
              map['unit']
                  ?.toString()
                  .trim() ??
              'piece',

      unitId:
          map['unit_id'] != null
              ? int.tryParse(
                  map['unit_id'].toString(),
                )
              : null,

      description:
          map['description']
                  ?.toString()
                  .trim() ??
              '',

      imagePath: resolvedImage,

      barcode:
          map['barcode']
                  ?.toString()
                  .trim() ??
              '',

      sgst:
          double.tryParse(
                map['tax_percentage']
                        ?.toString() ??
                    '0.0',
              ) ??
              0.0,

      cgst: 0.0,

      discount:
          double.tryParse(
                map['discount_percentage']
                        ?.toString() ??
                    '0.0',
              ) ??
              0.0,

      expiryDate: resolvedExpiryDate,

      supplier:
          map['supplier_name']
                  ?.toString()
                  .trim() ??
              map['supplier']
                  ?.toString()
                  .trim() ??
              '',

      supplierId:
          map['supplier_id'] != null
              ? int.tryParse(
                  map['supplier_id'].toString(),
                )
              : null,

      lsl:
          double.tryParse(
                map['minimum_stock']
                        ?.toString() ??
                    map['lsl']
                        ?.toString() ??
                    '10',
              )
              ?.toInt() ??
          10,

      status:
          map['status']
                  ?.toString()
                  .trim() ??
              'ACTIVE',
    );
  }
}