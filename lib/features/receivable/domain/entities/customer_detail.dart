/// Full detail for the "Receivable Details" screen — opened by tapping a
/// customer on the Receivable from Customers list. A summary block plus
/// every bill this customer has, each carrying its own paid/balance
/// breakdown so the list can show "PAID" / "PARTIAL" / "PENDING" per
/// invoice.
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

/// One bill row inside [CustomerDetail.bills]. Tapping a row pushes the
/// existing `InvoiceDetailsScreen(invoiceId: invoiceNumber)` (still shared
/// from the Reports feature).
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
