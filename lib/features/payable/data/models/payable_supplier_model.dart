import '../../domain/entities/payable_supplier.dart';

class PayableSupplierModel extends PayableSupplier {
  PayableSupplierModel({
    required super.id,
    required super.name,
    required super.supplierName,
    required super.companyName,
    required super.phone,
    required super.email,
    required super.orderCount,
    required super.totalAmount,
    required super.amount,
    required super.settledAmount,
    required super.outstandingAmount,
    super.lastPurchaseDate,
    required super.dueDate,
  });

  factory PayableSupplierModel.fromJson(Map<String, dynamic> json) {
    final sName = json['supplier_name']?.toString() ??
        json['name']?.toString() ??
        'Unknown Supplier';
    final total = (json['total_purchase_value'] as num?)?.toDouble() ??
        (json['amount'] as num?)?.toDouble() ??
        0.0;
    final lastDateStr = json['last_purchase_date']?.toString();
    DateTime parsedDue = DateTime.now().add(const Duration(days: 30));
    if (lastDateStr != null) {
      parsedDue = DateTime.tryParse(lastDateStr)?.add(const Duration(days: 30)) ?? parsedDue;
    }

    return PayableSupplierModel(
      id: json['id']?.toString() ?? '',
      name: sName,
      supplierName: sName,
      companyName: json['company_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      orderCount: (json['purchase_order_count'] as num?)?.toInt() ?? 0,
      totalAmount: total,
      amount: (json['outstanding_purchase_value'] as num?)?.toDouble() ?? total,
      settledAmount: (json['settled_purchase_value'] as num?)?.toDouble() ?? 0.0,
      outstandingAmount: (json['outstanding_purchase_value'] as num?)?.toDouble() ?? 0.0,
      lastPurchaseDate: lastDateStr,
      dueDate: parsedDue,
    );
  }
}
