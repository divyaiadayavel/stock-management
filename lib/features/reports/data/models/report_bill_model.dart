import '../../domain/entities/report_bill.dart';

/// Tolerant numeric parser — the backend sometimes sends numbers as
/// JSON numbers and sometimes as numeric strings depending on the
/// endpoint, so this handles both instead of assuming one shape.
double _num(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim()) ?? 0.0;
}

class ReportBillModel extends ReportBill {
  ReportBillModel({
    required super.id,
    required super.billId,
    required super.invoiceNumber,
    required super.customerName,
    required super.customerPhone,
    required super.invoiceDate,
    required super.date,
    required super.grandTotal,
    required super.totalAmount,
    required super.paymentMethod,
    required super.paymentStatus,
    required super.itemCount,
    required super.items,
    super.saleId,
    super.paidAmount,
    super.balanceAmount,
  });

  factory ReportBillModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] is Map<String, dynamic>
        ? json['customer'] as Map<String, dynamic>
        : null;

    final bId = json['id']?.toString() ?? '';
    final saleIdVal = int.tryParse(bId) ?? 0;
    final dStr = json['invoice_date']?.toString() ?? '';
    final parsedDate = DateTime.tryParse(dStr) ?? DateTime.now();
    final total = (json['grand_total'] as num?)?.toDouble() ?? 0.0;
    final count = (json['item_count'] as num?)?.toInt() ?? 0;
    final status = json['payment_status']?.toString() ?? 'PAID';

    // Prefer the backend's own paid_amount / balance_amount when they
    // are present (same columns used across the rest of the app). If
    // this particular report row doesn't include them, fall back to a
    // safe value derived from payment_status instead of leaving every
    // invoice looking unpaid.
    final double paid = json.containsKey('paid_amount')
        ? _num(json['paid_amount'])
        : (status.toUpperCase() == 'PAID' ? total : 0.0);

    final double balance = json.containsKey('balance_amount')
        ? _num(json['balance_amount'])
        : (status.toUpperCase() == 'PAID' ? 0.0 : total - paid);

    return ReportBillModel(
      id: bId,
      billId: bId,
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      customerName: customer?['name']?.toString() ??
          json['customer_name']?.toString() ??
          'Walk-in Customer',
      customerPhone: customer?['phone']?.toString() ??
          json['customer_phone']?.toString() ??
          '',
      invoiceDate: dStr,
      date: parsedDate,
      grandTotal: total,
      totalAmount: total,
      paymentMethod: json['payment_method']?.toString() ?? 'CASH',
      paymentStatus: status,
      itemCount: count,
      items: count,
      saleId: saleIdVal,
      paidAmount: paid,
      balanceAmount: balance,
    );
  }
}