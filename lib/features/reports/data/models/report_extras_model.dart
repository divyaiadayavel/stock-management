import '../../domain/entities/report_extras.dart';

class ReportOverviewSummaryModel extends ReportOverviewSummary {
  const ReportOverviewSummaryModel({
    super.totalSales = 0.0,
    super.totalUnitsSold = 0.0,
    super.totalPurchases = 0.0,
    super.totalUnitsBought = 0.0,
    super.serviceValue = 0.0,
    super.servicesCount = 0,
    super.expenseValue = 0.0,
    super.totalReceivable = 0.0,
    super.totalPayable = 0.0,
    super.totalInvoices = 0,
    super.activeProductsCount = 0,
    super.activeSuppliersCount = 0,
  });

  factory ReportOverviewSummaryModel.fromJson(Map<String, dynamic> json) {
    return ReportOverviewSummaryModel(
      totalSales: _toDouble(json['total_sales']),
      totalUnitsSold: _toDouble(json['total_units_sold']),
      totalPurchases: _toDouble(json['total_purchases']),
      totalUnitsBought: _toDouble(json['total_units_bought']),
      serviceValue: _toDouble(json['service_value']),
      servicesCount: _toInt(json['services_count']),
      expenseValue: _toDouble(json['expense_value']),
      totalReceivable: _toDouble(json['total_receivable']),
      totalPayable: _toDouble(json['total_payable']),
      totalInvoices: _toInt(json['total_invoices']),
      activeProductsCount: _toInt(json['active_products_count']),
      activeSuppliersCount: _toInt(json['active_suppliers_count']),
    );
  }
}

class ProductPerformanceModel extends ProductPerformance {
  const ProductPerformanceModel({
    required super.id,
    required super.productName,
    required super.sku,
    required super.barcode,
    required super.categoryName,
    required super.purchasePrice,
    required super.sellingPrice,
    required super.unitsSold,
    required super.remainingUnits,
    required super.revenue,
    required super.grossProfit,
    required super.profitMarginPercent,
    required super.marginPercent,
    required super.stockLeft,
    required super.costValue,
    required super.retailValue,
  });

  factory ProductPerformanceModel.fromJson(Map<String, dynamic> json) {
    final pPrice = _toDouble(json['purchase_price']);
    final sPrice = _toDouble(json['selling_price']);

    final rem = json['remaining_units'] != null
        ? _toDouble(json['remaining_units'])
        : _toDouble(json['current_stock']);

    final margin = _toDouble(json['profit_margin_percent']);

    return ProductPerformanceModel(
      id: _toInt(json['id']),
      productName: json['product_name']?.toString() ?? 'Unknown Product',
      sku: json['sku']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? 'General',
      purchasePrice: pPrice,
      sellingPrice: sPrice,
      unitsSold: _toDouble(json['units_sold']),
      remainingUnits: rem,
      revenue: _toDouble(json['revenue']),
      grossProfit: _toDouble(json['gross_profit']),
      profitMarginPercent: margin,
      marginPercent: margin,
      stockLeft: rem,
      costValue: rem * pPrice,
      retailValue: rem * sPrice,
    );
  }
}

class SupplierSummaryModel extends SupplierSummary {
  const SupplierSummaryModel({
    required super.id,
    required super.supplierCode,
    required super.supplierName,
    required super.companyName,
    required super.phone,
    required super.email,
    required super.purchaseOrderCount,
    required super.totalPurchaseValue,
    required super.settledPurchaseValue,
    required super.outstandingPurchaseValue,
    super.lastPurchaseDate,
    required super.sourcedProducts,
    required super.supplierId,
    required super.sourcedItems,
    required super.procurementValue,
  });

  factory SupplierSummaryModel.fromJson(Map<String, dynamic> json) {
    final supplierId =
        json['supplier_id']?.toString() ?? json['id']?.toString() ?? '';

    final total = _toDouble(json['total_purchase_value']);

    final sourcedProducts = json['sourced_products'] is List
        ? (json['sourced_products'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return SupplierSummaryModel(
      id: _toInt(json['id']),
      supplierCode: json['supplier_code']?.toString() ?? '',
      supplierName: json['supplier_name']?.toString() ?? 'Unknown Supplier',
      companyName: json['company_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      purchaseOrderCount: _toInt(json['purchase_order_count']),
      totalPurchaseValue: total,
      settledPurchaseValue: _toDouble(json['settled_purchase_value']),
      outstandingPurchaseValue:
          _toDouble(json['outstanding_purchase_value']) != 0
          ? _toDouble(json['outstanding_purchase_value'])
          : _toDouble(json['current_balance']),
      lastPurchaseDate: json['last_purchase_date']?.toString(),
      sourcedProducts: sourcedProducts,
      supplierId: supplierId,
      sourcedItems: sourcedProducts,
      procurementValue: total,
    );
  }
}

class StockMovementModel extends StockMovement {
  const StockMovementModel({
    required super.id,
    required super.productName,
    required super.sku,
    required super.barcode,
    required super.movementType,
    required super.direction,
    required super.quantity,
    required super.quantityChange,
    required super.stockBefore,
    required super.stockAfter,
    required super.unitCost,
    required super.reference,
    required super.tag,
    required super.createdAt,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    final qty = _toDouble(json['quantity']);

    final movementType = json['movement_type']?.toString() ?? '';

    final direction =
        json['direction']?.toString() ?? (qty >= 0 ? 'IN' : 'OUT');

    return StockMovementModel(
      id: _toInt(json['id']),
      productName: json['product_name']?.toString() ?? 'Unknown Product',
      sku: json['sku']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      movementType: movementType,
      direction: direction,
      quantity: qty,
      quantityChange: direction.toUpperCase() == 'OUT' ? -qty.abs() : qty.abs(),
      stockBefore: _toDouble(json['stock_before']),
      stockAfter: _toDouble(json['stock_after']),
      unitCost: _toDouble(json['unit_cost']),
      reference: json['reference']?.toString() ?? 'Manual',
      tag: json['tag']?.toString() ?? movementType,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class InvoiceDetailModel extends InvoiceDetail {
  const InvoiceDetailModel({
    super.invoiceId = '',
    super.invoiceNumber = '',
    super.customerName = '',
    super.customerPhone = '',
    required super.date,
    super.subtotal = 0.0,
    super.discount = 0.0,
    super.taxGst = 0.0,
    super.grandTotal = 0.0,
    super.paymentMode = 'CASH',
    super.splitCashAmount = 0.0,
    super.splitUpiAmount = 0.0,
    super.items = const [],
    super.payments = const [],
    super.saleId = 0,
    super.paidAmount = 0.0,
    super.balanceAmount = 0.0,
    super.paymentStatus = 'PAID',
  });

  factory InvoiceDetailModel.fromJson(Map<String, dynamic> json) {
    final saleData = json['sale'] is Map
        ? Map<String, dynamic>.from(json['sale'] as Map)
        : json;

    final itemsList = json['items'] is List
        ? List<dynamic>.from(json['items'] as List)
        : <dynamic>[];

    final paymentsList = json['payments'] is List
        ? List<dynamic>.from(json['payments'] as List)
        : <dynamic>[];

    final grandTotalVal = _toDouble(saleData['grand_total']);
    final saleIdVal = int.tryParse(saleData['id']?.toString() ?? '') ?? 0;
    final statusVal =
        saleData['payment_status']?.toString().toUpperCase() ?? '';

    // Prefer the backend's own paid_amount when present (same column
    // used across the rest of the app). Otherwise fall back to summing
    // the individual payment records we already fetched, and only then
    // to a status-based guess.
    double paidVal;
    if (saleData.containsKey('paid_amount')) {
      paidVal = _toDouble(saleData['paid_amount']);
    } else if (paymentsList.isNotEmpty) {
      paidVal = paymentsList.fold<double>(0.0, (sum, p) {
        if (p is Map) {
          return sum + _toDouble(p['amount']);
        }
        return sum;
      });
    } else {
      paidVal = statusVal == 'PENDING' ? 0.0 : grandTotalVal;
    }

    final double balanceVal = saleData.containsKey('balance_amount')
        ? _toDouble(saleData['balance_amount'])
        : (grandTotalVal - paidVal).clamp(0.0, double.infinity);

    final resolvedStatus = statusVal.isNotEmpty
        ? statusVal
        : (balanceVal <= 0.01
              ? 'PAID'
              : (paidVal <= 0.01 ? 'PENDING' : 'PARTIAL'));

    return InvoiceDetailModel(
      invoiceId: saleData['invoice_number']?.toString() ?? '',
      invoiceNumber: saleData['invoice_number']?.toString() ?? '',
      customerName: saleData['customer_name']?.toString() ?? 'Walk-in Customer',
      customerPhone: saleData['customer_phone']?.toString() ?? '',
      date:
          DateTime.tryParse(saleData['invoice_date']?.toString() ?? '') ??
          DateTime.now(),
      subtotal: _toDouble(saleData['subtotal']),
      discount: _toDouble(saleData['discount_amount']),
      taxGst: _toDouble(saleData['tax_amount']),
      grandTotal: grandTotalVal,
      paymentMode: saleData['payment_method']?.toString() ?? 'CASH',
      splitCashAmount: _toDouble(saleData['split_cash_amount']),
      splitUpiAmount: _toDouble(saleData['split_upi_amount']),
      items: itemsList,
      payments: paymentsList,
      saleId: saleIdVal,
      paidAmount: paidVal,
      balanceAmount: balanceVal,
      paymentStatus: resolvedStatus,
    );
  }
}

class PurchaseOrderDetailModel extends PurchaseOrderDetail {
  const PurchaseOrderDetailModel({
    super.poNumber = '',
    super.supplierName = '',
    required super.date,
    super.status = '',
    super.paymentStatus = '',
    super.subtotal = 0.0,
    super.taxOrShipping = 0.0,
    super.grandTotal = 0.0,
    super.items = const [],
  });

  factory PurchaseOrderDetailModel.fromJson(Map<String, dynamic> json) {
    final purchase = json['purchase'] is Map
        ? Map<String, dynamic>.from(json['purchase'] as Map)
        : <String, dynamic>{};

    final sup = purchase['supplier'] is Map
        ? Map<String, dynamic>.from(purchase['supplier'] as Map)
        : <String, dynamic>{};

    final dateString = purchase['purchase_date']?.toString();

    return PurchaseOrderDetailModel(
      poNumber: purchase['purchase_order_number']?.toString() ?? '',
      supplierName: sup['name']?.toString() ?? '',
      date: DateTime.tryParse(dateString ?? '') ?? DateTime.now(),
      status: purchase['status']?.toString() ?? '',
      paymentStatus: purchase['payment_status']?.toString() ?? '',
      subtotal: _toDouble(purchase['subtotal']),
      taxOrShipping:
          _toDouble(purchase['tax_amount']) +
          _toDouble(purchase['shipping_cost']),
      grandTotal: _toDouble(purchase['grand_total']),
      items: json['items'] is List
          ? List<dynamic>.from(json['items'] as List)
          : <dynamic>[],
    );
  }
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

class ServiceJobSummaryModel extends ServiceJobSummary {
  const ServiceJobSummaryModel({
    required super.id,
    required super.jobId,
    required super.requestNumber,
    required super.invoiceNumber,
    required super.serviceName,
    required super.serviceType,
    required super.categoryName,
    required super.customerName,
    required super.customerPhone,
    required super.amount,
    required super.status,
    required super.answerCount,
    required super.createdAt,
    required super.date,
    required super.fieldLabel,
    required super.fieldValue,
  });

  factory ServiceJobSummaryModel.fromJson(Map<String, dynamic> json) {
    final createdAt = json['created_at']?.toString() ?? '';

    final serviceName = json['service_name']?.toString() ?? 'Unknown Service';

    final status = json['status']?.toString() ?? 'SUBMITTED';

    return ServiceJobSummaryModel(
      id: _toInt(json['id']),
      jobId: json['id']?.toString() ?? '',
      requestNumber: json['request_number']?.toString() ?? '',
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      serviceName: serviceName,
      serviceType: serviceName,
      categoryName: json['category_name']?.toString() ?? 'General',
      customerName: json['customer_name']?.toString() ?? 'Walk-in Customer',
      customerPhone: json['customer_phone']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      status: status,
      answerCount: _toInt(json['answer_count']),
      createdAt: createdAt,
      date: DateTime.tryParse(createdAt) ?? DateTime.now(),
      fieldLabel: 'Status',
      fieldValue: status,
    );
  }
}

class ServiceJobDetailModel extends ServiceJobDetail {
  const ServiceJobDetailModel({
    super.serviceType = '',
    required super.date,
    super.serviceFee = 0.0,
    super.answers = const [],
    super.attachedDocument,
  });

  factory ServiceJobDetailModel.fromJson(Map<String, dynamic> json) {
    final request = json['request'] is Map
        ? Map<String, dynamic>.from(json['request'] as Map)
        : <String, dynamic>{};

    final service = request['service'] is Map
        ? Map<String, dynamic>.from(request['service'] as Map)
        : <String, dynamic>{};

    final dateString = request['created_at']?.toString() ?? '';

    final answers = json['answer_groups'] is List
        ? List<dynamic>.from(json['answer_groups'] as List)
        : json['answers'] is List
        ? List<dynamic>.from(json['answers'] as List)
        : <dynamic>[];

    return ServiceJobDetailModel(
      serviceType:
          service['name']?.toString() ??
          request['service_name']?.toString() ??
          '',
      date: DateTime.tryParse(dateString) ?? DateTime.now(),
      serviceFee: _toDouble(request['amount']),
      answers: answers,
      attachedDocument: null,
    );
  }
}

class ProfitabilityReportModel extends ProfitabilityReport {
  const ProfitabilityReportModel({
    super.grossTurnover = 0.0,
    super.directCosts = 0.0,
    super.salesRevenueTurnover = 0.0,
    super.servicesIncome = 0.0,
    super.costOfGoodsSold = 0.0,
    super.activeLedgerExpense = 0.0,
    super.estimatedNetProfit = 0.0,
    super.netMarginRate = 0.0,
    super.activeExpenses = const [],
  });

  factory ProfitabilityReportModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] is Map
        ? Map<String, dynamic>.from(json['summary'] as Map)
        : <String, dynamic>{};

    final expenses = json['expenses'] is Map
        ? Map<String, dynamic>.from(json['expenses'] as Map)
        : <String, dynamic>{};

    return ProfitabilityReportModel(
      grossTurnover: _toDouble(summary['total_revenue']),
      directCosts: _toDouble(summary['cogs']),
      salesRevenueTurnover: _toDouble(summary['sales_revenue']),
      servicesIncome: _toDouble(summary['service_revenue']),
      costOfGoodsSold: _toDouble(summary['cogs']),
      activeLedgerExpense: _toDouble(summary['operating_expenses']),
      estimatedNetProfit: _toDouble(summary['operating_profit']),
      netMarginRate: _toDouble(summary['operating_margin']),
      activeExpenses: expenses['recent'] is List
          ? List<dynamic>.from(expenses['recent'] as List)
          : <dynamic>[],
    );
  }
}

class InventoryStockSummaryModel extends InventoryStockSummary {
  const InventoryStockSummaryModel({
    super.stockValuation = 0.0,
    super.activeItems = 0,
    super.purchaseOrdersTotal = 0.0,
    super.pendingOrdered = 0.0,
  });

  factory InventoryStockSummaryModel.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] is Map
        ? Map<String, dynamic>.from(json['summary'] as Map)
        : json;

    return InventoryStockSummaryModel(
      stockValuation: _toDouble(summary['stock_valuation']),
      activeItems: _toInt(summary['active_items']),
      purchaseOrdersTotal: _toDouble(summary['purchase_orders_total']),
      pendingOrdered: _toDouble(summary['pending_ordered']),
    );
  }
}

class ReceivedOrderRowModel extends ReceivedOrderRow {
  const ReceivedOrderRowModel({
    required super.id,
    required super.poNumber,
    required super.supplierName,
    required super.purchaseDate,
    required super.receivedDate,
    required super.grandTotal,
    required super.amount,
    required super.paymentStatus,
    required super.purchaseStatus,
    required super.totalQuantity,
    required super.itemCount,
    super.itemNames,
    required super.itemsSummary,
  });

  factory ReceivedOrderRowModel.fromJson(Map<String, dynamic> json) {
    final supplier = json['supplier'] is Map
        ? Map<String, dynamic>.from(json['supplier'] as Map)
        : <String, dynamic>{};

    final purchaseDate = json['purchase_date']?.toString() ?? '';

    final total = _toDouble(json['grand_total']);

    final names =
        json['item_names']?.toString() ??
        json['item_details']?.toString() ??
        '';

    return ReceivedOrderRowModel(
      id: _toInt(json['id']),
      poNumber: json['purchase_order_number']?.toString() ?? '',
      supplierName:
          supplier['name']?.toString() ??
          json['supplier_name']?.toString() ??
          'Unknown Supplier',
      purchaseDate: purchaseDate,
      receivedDate: DateTime.tryParse(purchaseDate) ?? DateTime.now(),
      grandTotal: total,
      amount: total,
      paymentStatus: json['payment_status']?.toString() ?? '',
      purchaseStatus: json['purchase_status']?.toString() ?? '',
      totalQuantity: _toDouble(json['total_quantity']),
      itemCount: _toInt(json['item_count']),
      itemNames: names,
      itemsSummary: names,
    );
  }
}

class PendingOrderRowModel extends PendingOrderRow {
  const PendingOrderRowModel({
    required super.id,
    required super.poNumber,
    required super.supplierName,
    required super.purchaseDate,
    required super.orderedDate,
    required super.grandTotal,
    required super.amount,
    required super.paymentStatus,
    required super.purchaseStatus,
    required super.status,
    required super.totalQuantity,
    required super.itemCount,
    super.itemNames,
    required super.itemsSummary,
  });

  factory PendingOrderRowModel.fromJson(Map<String, dynamic> json) {
    final supplier = json['supplier'] is Map
        ? Map<String, dynamic>.from(json['supplier'] as Map)
        : <String, dynamic>{};

    final purchaseDate = json['purchase_date']?.toString() ?? '';

    final total = _toDouble(json['grand_total']);

    final purchaseStatus = json['purchase_status']?.toString() ?? 'PENDING';

    final names =
        json['item_names']?.toString() ??
        json['item_details']?.toString() ??
        '';

    return PendingOrderRowModel(
      id: _toInt(json['id']),
      poNumber: json['purchase_order_number']?.toString() ?? '',
      supplierName:
          supplier['name']?.toString() ??
          json['supplier_name']?.toString() ??
          'Unknown Supplier',
      purchaseDate: purchaseDate,
      orderedDate: DateTime.tryParse(purchaseDate) ?? DateTime.now(),
      grandTotal: total,
      amount: total,
      paymentStatus: json['payment_status']?.toString() ?? '',
      purchaseStatus: purchaseStatus,
      status: purchaseStatus,
      totalQuantity: _toDouble(json['total_quantity']),
      itemCount: _toInt(json['item_count']),
      itemNames: names,
      itemsSummary: names,
    );
  }
}

class LowStockAlertRowModel extends LowStockAlertRow {
  const LowStockAlertRowModel({
    required super.id,
    required super.productName,
    required super.sku,
    required super.categoryName,
    required super.supplierName,
    required super.currentStock,
    required super.reorderLevel,
    required super.minReorderLevel,
    required super.unitsLeft,
    required super.status,
    required super.severity,
    required super.purchasePrice,
  });

  factory LowStockAlertRowModel.fromJson(Map<String, dynamic> json) {
    final currentStock = _toDouble(json['current_stock']);

    final reorderLevel = _toDouble(json['reorder_level']);

    return LowStockAlertRowModel(
      id: _toInt(json['id']),
      productName: json['product_name']?.toString() ?? 'Unknown Product',
      sku: json['sku']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? 'General',
      supplierName: json['supplier_name']?.toString() ?? 'Primary Supplier',
      currentStock: currentStock,
      reorderLevel: reorderLevel,
      minReorderLevel: reorderLevel,
      unitsLeft: currentStock,
      status:
          json['status']?.toString() ??
          (currentStock <= 0 ? 'OUT_OF_STOCK' : 'LOW_STOCK'),
      severity: _toInt(json['severity']) != 0
          ? _toInt(json['severity'])
          : (currentStock <= 0 ? 3 : 1),
      purchasePrice: _toDouble(json['purchase_price']),
    );
  }
}

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

// ═══════════════════════════════════════════════════════════════════════
// Customer Receivable Details
// action=customer_detail&id=<customer_id>
// ═══════════════════════════════════════════════════════════════════════

class ReportBillSummaryModel extends ReportBillSummary {
  const ReportBillSummaryModel({
    super.invoiceId,
    super.invoiceNumber,
    required super.date,
    super.grandTotal,
    super.paidAmount,
    super.balanceAmount,
    super.paymentStatus,
    super.itemCount,
    super.itemsSummary,
  });

  factory ReportBillSummaryModel.fromJson(Map<String, dynamic> json) {
    final dateStr =
        json['invoice_date']?.toString() ?? json['date']?.toString();
    return ReportBillSummaryModel(
      invoiceId: json['id']?.toString() ?? json['invoice_id']?.toString() ?? '',
      invoiceNumber:
          json['invoice_number']?.toString() ??
          json['bill_id']?.toString() ??
          '',
      date: dateStr != null
          ? (DateTime.tryParse(dateStr) ?? DateTime.now())
          : DateTime.now(),
      grandTotal: _toDouble(json['grand_total'] ?? json['total_amount']),
      paidAmount: _toDouble(json['paid_amount']),
      balanceAmount: _toDouble(json['balance_amount']),
      paymentStatus:
          json['payment_status']?.toString().toUpperCase() ?? 'PENDING',
      itemCount: _toInt(json['item_count']),
      itemsSummary: json['items_summary']?.toString() ?? '',
    );
  }
}

class CustomerDetailModel extends CustomerDetail {
  const CustomerDetailModel({
    super.id,
    super.customerName,
    super.phone,
    super.totalSalesValue,
    super.settledAmount,
    super.outstandingBalance,
    super.invoiceCount,
    super.bills,
  });

  factory CustomerDetailModel.fromJson(Map<String, dynamic> json) {
    // Same shape convention as SupplierDetailModel: an optional nested
    // `customer` object, an optional nested `summary` object, and the
    // bill rows under either `invoices` or `bills`.
    final customer = json['customer'] is Map
        ? Map<String, dynamic>.from(json['customer'] as Map)
        : <String, dynamic>{};

    final summary = json['summary'] is Map
        ? Map<String, dynamic>.from(json['summary'] as Map)
        : <String, dynamic>{};

    final rawBills = json['invoices'] ?? json['bills'];
    final List<ReportBillSummary> bills = [];
    if (rawBills is List) {
      for (final item in rawBills) {
        if (item is Map) {
          bills.add(
            ReportBillSummaryModel.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return CustomerDetailModel(
      id: (customer['id'] ?? json['customer_id'] ?? json['id'])?.toString() ?? '',
      customerName:
          customer['name']?.toString() ??
          customer['customer_name']?.toString() ??
          json['customer_name']?.toString() ??
          'Walk-in Customer',
      phone: customer['phone']?.toString() ?? json['phone']?.toString() ?? '',
      totalSalesValue: _toDouble(
        summary['total_sales_value'] ?? json['total_sales_value'],
      ),
      settledAmount: _toDouble(
        summary['settled_amount'] ?? json['settled_amount'],
      ),
      outstandingBalance: _toDouble(
        summary['outstanding_balance'] ?? json['outstanding_balance'],
      ),
      invoiceCount: _toInt(
        summary['invoice_count'] ?? json['invoice_count'] ?? bills.length,
      ),
      bills: bills,
    );
  }
}
