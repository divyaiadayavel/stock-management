class ReportBill {
  final String id;
  final String billId;
  final String invoiceNumber;
  final String customerName;
  final String customerPhone;
  final String invoiceDate;
  final DateTime date;
  final double grandTotal;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final int itemCount;
  final int items;

  /// Numeric sale id (the primary key on the `sales` table). Needed to
  /// call add_payment.php from the invoice details screen. 0 when not
  /// resolvable (should not normally happen).
  final int saleId;

  /// Amount already paid on this invoice. Comes straight from the
  /// backend's `paid_amount` column when present.
  final double paidAmount;

  /// Amount still outstanding on this invoice. Comes straight from the
  /// backend's `balance_amount` column when present.
  final double balanceAmount;

  const ReportBill({
    required this.id,
    required this.billId,
    required this.invoiceNumber,
    required this.customerName,
    required this.customerPhone,
    required this.invoiceDate,
    required this.date,
    required this.grandTotal,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.itemCount,
    required this.items,
    this.saleId = 0,
    this.paidAmount = 0.0,
    this.balanceAmount = 0.0,
  });

  String get _normalizedStatus => paymentStatus.trim().toLowerCase();

  /// True for a bill that was paid in part but still has money owed
  /// on it (payment_status = PARTIAL, plus a few legacy spellings).
  bool get isPartialStatus {
    final status = _normalizedStatus;
    return status == 'partial' ||
        status == 'partial_cash' ||
        status == 'partial cash' ||
        status == 'split' ||
        status == 'split_tender' ||
        status == 'split tender';
  }

  /// True for a bill with nothing paid yet (payment_status = PENDING /
  /// CREDIT, plus a few legacy spellings).
  bool get isPendingStatus {
    final status = _normalizedStatus;
    return status == 'pending' ||
        status == 'unpaid' ||
        status == 'due' ||
        status == 'payment_pending' ||
        status == 'credit';
  }

  /// True whenever this bill still has an outstanding balance to
  /// collect — whether it was left completely unpaid or only
  /// partially paid. Used to power the "Pending" list on the
  /// Dashboard and the "Pending" filter on the Sales Report screen.
  bool get hasOutstandingBalance => isPartialStatus || isPendingStatus;
}