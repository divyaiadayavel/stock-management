class ReceivableCustomer {
  final String id;
  final String name;
  final String customerName;
  final String phone;
  final double totalSales;
  final double amount;
  final int invoiceCount;
  final String? lastInvoiceDate;
  final DateTime dueDate;

  const ReceivableCustomer({
    required this.id,
    required this.name,
    required this.customerName,
    required this.phone,
    required this.totalSales,
    required this.amount,
    required this.invoiceCount,
    this.lastInvoiceDate,
    required this.dueDate,
  });
}
