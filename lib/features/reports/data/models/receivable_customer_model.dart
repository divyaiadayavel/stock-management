import '../../domain/entities/receivable_customer.dart';

class ReceivableCustomerModel extends ReceivableCustomer {
  ReceivableCustomerModel({
    required super.id,
    required super.name,
    required super.customerName,
    required super.phone,
    required super.totalSales,
    required super.amount,
    required super.invoiceCount,
    super.lastInvoiceDate,
    required super.dueDate,
  });

  factory ReceivableCustomerModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] is Map<String, dynamic>
        ? json['customer'] as Map<String, dynamic>
        : null;

    final customerId = customer?['id']?.toString() ??
        json['customer_id']?.toString() ??
        json['id']?.toString() ??
        '';

    final cName = customer?['name']?.toString() ??
        json['customer_name']?.toString() ??
        'Walk-in Customer';

    final total = (json['grand_total'] as num?)?.toDouble() ??
        (json['total_sales'] as num?)?.toDouble() ??
        0.0;

    final dateStr = json['invoice_date']?.toString();
    DateTime parsedDue = DateTime.now().add(const Duration(days: 15));
    if (dateStr != null) {
      parsedDue = DateTime.tryParse(dateStr)?.add(const Duration(days: 15)) ?? parsedDue;
    }

    return ReceivableCustomerModel(
      id: customerId,
      name: cName,
      customerName: cName,
      phone: customer?['phone']?.toString() ?? json['phone']?.toString() ?? '',
      totalSales: total,
      amount: total,
      invoiceCount: (json['item_count'] as num?)?.toInt() ?? 1,
      lastInvoiceDate: dateStr,
      dueDate: parsedDue,
    );
  }
}