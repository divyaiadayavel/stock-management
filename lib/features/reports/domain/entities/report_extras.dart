enum ReportChartFilter { day, week, month, year, custom }

class ReportChartPoint {
  final String label;
  final double amount;
  const ReportChartPoint({required this.label, required this.amount});
}

class ReportOverviewSummary {
  final double totalSales;
  final double totalUnitsSold;
  final double totalPurchases;
  final double totalUnitsBought;
  final double serviceValue;
  final int servicesCount;
  final double expenseValue;
  final double totalReceivable;
  final double totalPayable;
  final int totalInvoices;
  final int activeProductsCount;
  final int activeSuppliersCount;

  const ReportOverviewSummary({
    this.totalSales = 0.0,
    this.totalUnitsSold = 0.0,
    this.totalPurchases = 0.0,
    this.totalUnitsBought = 0.0,
    this.serviceValue = 0.0,
    this.servicesCount = 0,
    this.expenseValue = 0.0,
    this.totalReceivable = 0.0,
    this.totalPayable = 0.0,
    this.totalInvoices = 0,
    this.activeProductsCount = 0,
    this.activeSuppliersCount = 0,
  });
}

class ProductPerformance {
  final int id;
  final String productName;
  final String sku;
  final String barcode;
  final String categoryName;
  final double purchasePrice;
  final double sellingPrice;
  final double unitsSold;
  final double remainingUnits;
  final double revenue;
  final double grossProfit;
  final double profitMarginPercent;
  final double marginPercent;
  final double stockLeft;
  final double costValue;
  final double retailValue;

  const ProductPerformance({
    required this.id,
    required this.productName,
    required this.sku,
    required this.barcode,
    required this.categoryName,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.unitsSold,
    required this.remainingUnits,
    required this.revenue,
    required this.grossProfit,
    required this.profitMarginPercent,
    required this.marginPercent,
    required this.stockLeft,
    required this.costValue,
    required this.retailValue,
  });
}

class SupplierSummary {
  final int id;
  final String supplierCode;
  final String supplierName;
  final String companyName;
  final String phone;
  final String email;
  final int purchaseOrderCount;
  final double totalPurchaseValue;
  final double settledPurchaseValue;
  final double outstandingPurchaseValue;
  final String? lastPurchaseDate;
  final List<String> sourcedProducts;
  final String supplierId;
  final List<String> sourcedItems;
  final double procurementValue;

  const SupplierSummary({
    required this.id,
    required this.supplierCode,
    required this.supplierName,
    required this.companyName,
    required this.phone,
    required this.email,
    required this.purchaseOrderCount,
    required this.totalPurchaseValue,
    required this.settledPurchaseValue,
    required this.outstandingPurchaseValue,
    this.lastPurchaseDate,
    required this.sourcedProducts,
    required this.supplierId,
    required this.sourcedItems,
    required this.procurementValue,
  });
}

class SupplierProductRow {
  final int id;
  final String productName;
  final String? sku;
  final int purchaseCount;
  final double totalQuantity;
  final double totalValue;
  final double lastUnitPrice;
  final String? lastPurchaseDate;

  const SupplierProductRow({
    required this.id,
    required this.productName,
    this.sku,
    required this.purchaseCount,
    required this.totalQuantity,
    required this.totalValue,
    required this.lastUnitPrice,
    this.lastPurchaseDate,
  });
}

class SupplierDetail {
  final int id;
  final String supplierName;
  final String phone;
  final String category;
  final double totalProcurementValue;
  final double settledInvoices;
  final double outstandingBalance;
  final int purchaseOrderCount;
  final List<PurchaseOrderSummary> orders;
  final List<SupplierProductRow> products;

  const SupplierDetail({
    this.id = 0,
    this.supplierName = '',
    this.phone = '',
    this.category = 'General',
    this.totalProcurementValue = 0.0,
    this.settledInvoices = 0.0,
    this.outstandingBalance = 0.0,
    this.purchaseOrderCount = 0,
    this.orders = const [],
    this.products = const [],
  });
}

class PurchaseOrderDetail {
  final String poNumber;
  final String supplierName;
  final DateTime date;
  final String status;
  final String paymentStatus;
  final double subtotal;
  final double taxOrShipping;
  final double grandTotal;
  final List<dynamic> items;

  const PurchaseOrderDetail({
    this.poNumber = '',
    this.supplierName = '',
    required this.date,
    this.status = '',
    this.paymentStatus = '',
    this.subtotal = 0.0,
    this.taxOrShipping = 0.0,
    this.grandTotal = 0.0,
    this.items = const [],
  });
}

class InvoiceDetail {
  final String invoiceId;
  final String invoiceNumber;
  final String customerName;
  final String customerPhone;
  final DateTime date;
  final double subtotal;
  final double discount;
  final double taxGst;
  final double grandTotal;
  final String paymentMode;
  final double splitCashAmount;
  final double splitUpiAmount;
  final List<dynamic> items;
  final List<dynamic> payments;

  /// Numeric sale id (primary key on the `sales` table). Needed to call
  /// add_payment.php from the "Balance Payment" button. 0 when not
  /// resolvable (should not normally happen).
  final int saleId;

  /// Amount already paid on this invoice, straight from the backend's
  /// `paid_amount` column when present.
  final double paidAmount;

  /// Amount still outstanding on this invoice, straight from the
  /// backend's `balance_amount` column when present.
  final double balanceAmount;

  /// PAID / PARTIAL / PENDING, straight from the backend's
  /// `payment_status` column.
  final String paymentStatus;

  const InvoiceDetail({
    this.invoiceId = '',
    this.invoiceNumber = '',
    this.customerName = '',
    this.customerPhone = '',
    required this.date,
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.taxGst = 0.0,
    this.grandTotal = 0.0,
    this.paymentMode = 'CASH',
    this.splitCashAmount = 0.0,
    this.splitUpiAmount = 0.0,
    this.items = const [],
    this.payments = const [],
    this.saleId = 0,
    this.paidAmount = 0.0,
    this.balanceAmount = 0.0,
    this.paymentStatus = 'PAID',
  });
}

class ServiceJobSummary {
  final int id;
  final String jobId;
  final String requestNumber;
  final String invoiceNumber;
  final String serviceName;
  final String serviceType;
  final String categoryName;
  final String customerName;
  final String customerPhone;
  final double amount;
  final String status;
  final int answerCount;
  final String createdAt;
  final DateTime date;
  final String fieldLabel;
  final String fieldValue;

  const ServiceJobSummary({
    required this.id,
    required this.jobId,
    required this.requestNumber,
    required this.invoiceNumber,
    required this.serviceName,
    required this.serviceType,
    required this.categoryName,
    required this.customerName,
    required this.customerPhone,
    required this.amount,
    required this.status,
    required this.answerCount,
    required this.createdAt,
    required this.date,
    required this.fieldLabel,
    required this.fieldValue,
  });
}

class ServiceJobDetail {
  final String serviceType;
  final DateTime date;
  final double serviceFee;
  final List<dynamic> answers;
  final dynamic attachedDocument;

  const ServiceJobDetail({
    this.serviceType = '',
    required this.date,
    this.serviceFee = 0.0,
    this.answers = const [],
    this.attachedDocument,
  });
}

class ProfitabilityReport {
  final double grossTurnover;
  final double directCosts;
  final double salesRevenueTurnover;
  final double servicesIncome;
  final double costOfGoodsSold;
  final double activeLedgerExpense;
  final double estimatedNetProfit;
  final double netMarginRate;
  final List<dynamic> activeExpenses;

  const ProfitabilityReport({
    this.grossTurnover = 0.0,
    this.directCosts = 0.0,
    this.salesRevenueTurnover = 0.0,
    this.servicesIncome = 0.0,
    this.costOfGoodsSold = 0.0,
    this.activeLedgerExpense = 0.0,
    this.estimatedNetProfit = 0.0,
    this.netMarginRate = 0.0,
    this.activeExpenses = const [],
  });
}

class InventoryStockSummary {
  final double stockValuation;
  final int activeItems;
  final double purchaseOrdersTotal;
  final double pendingOrdered;

  const InventoryStockSummary({
    this.stockValuation = 0.0,
    this.activeItems = 0,
    this.purchaseOrdersTotal = 0.0,
    this.pendingOrdered = 0.0,
  });
}

class StockMovement {
  final int id;
  final String productName;
  final String sku;
  final String barcode;
  final String movementType;
  final String direction;
  final double quantity;
  final double quantityChange;
  final double stockBefore;
  final double stockAfter;
  final double unitCost;
  final String reference;
  final String tag;
  final String createdAt;

  const StockMovement({
    required this.id,
    required this.productName,
    required this.sku,
    required this.barcode,
    required this.movementType,
    required this.direction,
    required this.quantity,
    required this.quantityChange,
    required this.stockBefore,
    required this.stockAfter,
    required this.unitCost,
    required this.reference,
    required this.tag,
    required this.createdAt,
  });
}

class ReceivedOrderRow {
  final int id;
  final String poNumber;
  final String supplierName;
  final String purchaseDate;
  final DateTime receivedDate;
  final double grandTotal;
  final double amount;
  final String paymentStatus;
  final String purchaseStatus;
  final double totalQuantity;
  final int itemCount;
  final String? itemNames;
  final String itemsSummary;

  const ReceivedOrderRow({
    required this.id,
    required this.poNumber,
    required this.supplierName,
    required this.purchaseDate,
    required this.receivedDate,
    required this.grandTotal,
    required this.amount,
    required this.paymentStatus,
    required this.purchaseStatus,
    required this.totalQuantity,
    required this.itemCount,
    this.itemNames,
    required this.itemsSummary,
  });
}

class PendingOrderRow {
  final int id;
  final String poNumber;
  final String supplierName;
  final String purchaseDate;
  final DateTime orderedDate;
  final double grandTotal;
  final double amount;
  final String paymentStatus;
  final String purchaseStatus;
  final String status;
  final double totalQuantity;
  final int itemCount;
  final String? itemNames;
  final String itemsSummary;

  const PendingOrderRow({
    required this.id,
    required this.poNumber,
    required this.supplierName,
    required this.purchaseDate,
    required this.orderedDate,
    required this.grandTotal,
    required this.amount,
    required this.paymentStatus,
    required this.purchaseStatus,
    required this.status,
    required this.totalQuantity,
    required this.itemCount,
    this.itemNames,
    required this.itemsSummary,
  });
}

/// Row shape for the top-level "Purchase Orders" tab on the Purchases &
/// Suppliers screen (Card 3) — every PO regardless of status, so the
/// screen can locally filter into Pending / Completed. Tapping a row opens
/// the full [PurchaseOrderDetail] breakdown via [poNumber].
class PurchaseOrderSummary {
  final int id;
  final String poNumber;
  final String supplierName;
  final String phone;
  final DateTime purchaseDate;
  final double grandTotal;
  final String paymentStatus;
  final String purchaseStatus;
  final int itemCount;
  final double totalQuantity;
  final String itemsSummary;

  /// Amount already paid on this purchase order. Straight from the
  /// backend's `paid_amount` column when present — used by the Payable
  /// Details screen to show a per-purchase paid/balance breakdown.
  final double paidAmount;

  /// Amount still owed on this purchase order. Straight from the
  /// backend's `balance_amount` column when present.
  final double balanceAmount;

  const PurchaseOrderSummary({
    required this.id,
    required this.poNumber,
    required this.supplierName,
    required this.phone,
    required this.purchaseDate,
    required this.grandTotal,
    required this.paymentStatus,
    required this.purchaseStatus,
    required this.itemCount,
    required this.totalQuantity,
    required this.itemsSummary,
    this.paidAmount = 0.0,
    this.balanceAmount = 0.0,
  });
}

class LowStockAlertRow {
  final int id;
  final String productName;
  final String sku;
  final String categoryName;
  final String supplierName;
  final double currentStock;
  final double reorderLevel;
  final double minReorderLevel;
  final double unitsLeft;
  final String status;
  final int severity;
  final double purchasePrice;

  const LowStockAlertRow({
    required this.id,
    required this.productName,
    required this.sku,
    required this.categoryName,
    required this.supplierName,
    required this.currentStock,
    required this.reorderLevel,
    required this.minReorderLevel,
    required this.unitsLeft,
    required this.status,
    required this.severity,
    required this.purchasePrice,
  });
}

/// Full detail for the "Customer Receivable Details" screen — opened by
/// tapping a customer on the Receivable from Customers list. Mirrors
/// [SupplierDetail] on the payable side: a summary block plus every bill
/// this customer has, each carrying its own paid/balance breakdown so
/// the list can show "PAID" / "PARTIAL" / "PENDING" per invoice.
class CustomerDetail {
  final String id;
  final String customerName;
  final String phone;
  final double totalSalesValue;
  final double settledAmount;
  final double outstandingBalance;
  final int invoiceCount;
  final List<ReportBillSummary> bills;

  const CustomerDetail({
    this.id = '',
    this.customerName = '',
    this.phone = '',
    this.totalSalesValue = 0.0,
    this.settledAmount = 0.0,
    this.outstandingBalance = 0.0,
    this.invoiceCount = 0,
    this.bills = const [],
  });
}

/// One bill row inside [CustomerDetail.bills]. Kept separate from the
/// Sales Reports' [ReportBill] entity (different screen, different
/// backend action) but shaped the same way so the same
/// paid/balance/payment-status rendering logic applies. Tapping a row
/// pushes the existing `InvoiceDetailsScreen(invoiceId: invoiceNumber)`.
class ReportBillSummary {
  final String invoiceId;
  final String invoiceNumber;
  final DateTime date;
  final double grandTotal;
  final double paidAmount;
  final double balanceAmount;
  final String paymentStatus;
  final int itemCount;
  final String itemsSummary;

  const ReportBillSummary({
    this.invoiceId = '',
    this.invoiceNumber = '',
    required this.date,
    this.grandTotal = 0.0,
    this.paidAmount = 0.0,
    this.balanceAmount = 0.0,
    this.paymentStatus = 'PENDING',
    this.itemCount = 0,
    this.itemsSummary = '',
  });
}
