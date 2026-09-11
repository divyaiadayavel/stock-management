/// Full detail for the "Payable Details" screen — opened by tapping a
/// supplier on the Payable to Suppliers list. Shows a summary block plus
/// every purchase made from this supplier, each carrying its own
/// paid/balance breakdown so the list can show "PAID" / "PARTIAL" /
/// "PENDING" per purchase order.
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

/// Row shape for every purchase order raised with a supplier. Tapping a
/// row opens the full purchase-order breakdown via [poNumber].
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
