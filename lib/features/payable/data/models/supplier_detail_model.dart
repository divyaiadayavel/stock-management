import '../../domain/entities/supplier_detail.dart';

/* ============================================================
   SHARED PARSING HELPERS
   ============================================================ */

double _toDouble(dynamic value) {
  if (value == null) {
    return 0.0;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString().trim()) ?? 0.0;
}

int _toInt(dynamic value) {
  if (value == null) {
    return 0;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString().trim()) ?? 0;
}

/* ============================================================
   SUPPLIER PRODUCT
   ============================================================ */

class SupplierProductRowModel extends SupplierProductRow {
  const SupplierProductRowModel({
    required super.id,
    required super.productName,
    super.sku,
    required super.purchaseCount,
    required super.totalQuantity,
    required super.totalValue,
    required super.lastUnitPrice,
    super.lastPurchaseDate,
  });

  factory SupplierProductRowModel.fromJson(Map<String, dynamic> json) {
    return SupplierProductRowModel(
      id: _toInt(json['id']),
      productName:
          json['product_name']?.toString() ??
          json['productName']?.toString() ??
          'Unknown Product',
      sku: json['sku']?.toString(),
      purchaseCount: _toInt(json['purchase_count'] ?? json['purchaseCount']),
      totalQuantity: _toDouble(json['total_quantity'] ?? json['totalQuantity']),
      totalValue: _toDouble(json['total_value'] ?? json['totalValue']),
      lastUnitPrice: _toDouble(
        json['last_unit_price'] ?? json['lastUnitPrice'],
      ),
      lastPurchaseDate:
          json['last_purchase_date']?.toString() ??
          json['lastPurchaseDate']?.toString(),
    );
  }
}

/* ============================================================
   PURCHASE ORDER SUMMARY
   ============================================================ */

class PurchaseOrderSummaryModel extends PurchaseOrderSummary {
  const PurchaseOrderSummaryModel({
    required super.id,
    required super.poNumber,
    required super.supplierName,
    required super.phone,
    required super.purchaseDate,
    required super.grandTotal,
    required super.paymentStatus,
    required super.purchaseStatus,
    required super.itemCount,
    required super.totalQuantity,
    required super.itemsSummary,
    super.paidAmount,
    super.balanceAmount,
  });

  factory PurchaseOrderSummaryModel.fromJson(Map<String, dynamic> json) {
    final supplier = json['supplier'] is Map
        ? Map<String, dynamic>.from(json['supplier'] as Map)
        : <String, dynamic>{};

    final dateString =
        json['purchase_date']?.toString() ??
        json['purchaseDate']?.toString() ??
        '';

    final itemNames =
        json['item_names']?.toString() ??
        json['item_details']?.toString() ??
        json['items_summary']?.toString() ??
        '';

    return PurchaseOrderSummaryModel(
      id: _toInt(json['id']),
      poNumber:
          json['purchase_order_number']?.toString() ??
          json['po_number']?.toString() ??
          json['poNumber']?.toString() ??
          '',
      supplierName:
          supplier['name']?.toString() ??
          supplier['supplier_name']?.toString() ??
          json['supplier_name']?.toString() ??
          'Unknown Supplier',
      phone: supplier['phone']?.toString() ?? json['phone']?.toString() ?? '',
      purchaseDate: DateTime.tryParse(dateString) ?? DateTime.now(),
      grandTotal: _toDouble(json['grand_total'] ?? json['grandTotal']),
      paymentStatus:
          json['payment_status']?.toString() ??
          json['paymentStatus']?.toString() ??
          '',
      purchaseStatus:
          json['purchase_status']?.toString() ??
          json['purchaseStatus']?.toString() ??
          json['status']?.toString() ??
          '',
      itemCount: _toInt(json['item_count'] ?? json['itemCount']),
      totalQuantity: _toDouble(json['total_quantity'] ?? json['totalQuantity']),
      itemsSummary: itemNames,
      paidAmount: _toDouble(json['paid_amount']),
      balanceAmount: _toDouble(json['balance_amount']),
    );
  }
}

/* ============================================================
   SUPPLIER DETAIL
   action=supplier_detail&id=<supplier_id>
   ============================================================ */

class SupplierDetailModel extends SupplierDetail {
  const SupplierDetailModel({
    super.id = 0,
    super.supplierName = '',
    super.phone = '',
    super.category = 'General',
    super.totalProcurementValue = 0.0,
    super.settledInvoices = 0.0,
    super.outstandingBalance = 0.0,
    super.purchaseOrderCount = 0,
    super.orders = const [],
    super.products = const [],
  });

  factory SupplierDetailModel.fromJson(Map<String, dynamic> json) {
    /*
     * ----------------------------------------------------------
     * Supplier information
     * ----------------------------------------------------------
     */

    final supplier = json['supplier'] is Map
        ? Map<String, dynamic>.from(json['supplier'] as Map)
        : <String, dynamic>{};

    /*
     * ----------------------------------------------------------
     * Summary information
     * ----------------------------------------------------------
     */

    final summary = json['summary'] is Map
        ? Map<String, dynamic>.from(json['summary'] as Map)
        : <String, dynamic>{};

    /*
     * ----------------------------------------------------------
     * Orders
     *
     * Backend may call this:
     *   recent_purchases
     *   orders
     * ----------------------------------------------------------
     */

    final rawOrders = json['recent_purchases'] ?? json['orders'];

    final List<PurchaseOrderSummary> orders = [];

    if (rawOrders is List) {
      for (final item in rawOrders) {
        if (item is Map) {
          orders.add(
            PurchaseOrderSummaryModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    /*
     * ----------------------------------------------------------
     * Products
     *
     * Backend may call this:
     *   linked_products
     *   products
     * ----------------------------------------------------------
     */

    final rawProducts = json['linked_products'] ?? json['products'];

    final List<SupplierProductRow> products = [];

    if (rawProducts is List) {
      for (final item in rawProducts) {
        if (item is Map) {
          products.add(
            SupplierProductRowModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    /*
     * ----------------------------------------------------------
     * Return complete SupplierDetail
     * ----------------------------------------------------------
     */

    return SupplierDetailModel(
      id: _toInt(supplier['id'] ?? json['supplier_id'] ?? json['id']),

      supplierName:
          supplier['supplier_name']?.toString() ??
          supplier['name']?.toString() ??
          json['supplier_name']?.toString() ??
          '',

      phone: supplier['phone']?.toString() ?? json['phone']?.toString() ?? '',

      category:
          supplier['category']?.toString() ??
          json['category']?.toString() ??
          'General',

      totalProcurementValue: _toDouble(
        summary['total_purchase_value'] ??
            summary['total_procurement_value'] ??
            json['total_purchase_value'],
      ),

      settledInvoices: _toDouble(
        summary['settled_purchase_value'] ??
            summary['settled_invoices'] ??
            json['settled_purchase_value'],
      ),

      outstandingBalance: _toDouble(
        summary['outstanding_purchase_value'] ??
            summary['outstanding_balance'] ??
            json['outstanding_purchase_value'],
      ),

      purchaseOrderCount: _toInt(
        summary['purchase_order_count'] ??
            json['purchase_order_count'] ??
            orders.length,
      ),

      orders: orders,

      products: products,
    );
  }
}
