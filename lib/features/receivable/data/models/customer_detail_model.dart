import '../../domain/entities/customer_detail.dart';

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
   REPORT BILL SUMMARY
   ============================================================ */

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

/* ============================================================
   CUSTOMER DETAIL
   action=customer_detail&id=<customer_id>
   ============================================================ */

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
