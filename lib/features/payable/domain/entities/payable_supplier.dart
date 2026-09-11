class PayableSupplier {
  final String id;
  final String name;
  final String supplierName;
  final String companyName;
  final String phone;
  final String email;
  final int orderCount;
  final double totalAmount;
  final double amount;
  final double settledAmount;
  final double outstandingAmount;
  final String? lastPurchaseDate;
  final DateTime dueDate;

  const PayableSupplier({
    required this.id,
    required this.name,
    required this.supplierName,
    required this.companyName,
    required this.phone,
    required this.email,
    required this.orderCount,
    required this.totalAmount,
    required this.amount,
    required this.settledAmount,
    required this.outstandingAmount,
    this.lastPurchaseDate,
    required this.dueDate,
  });
}
