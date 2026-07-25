import '../../data/models/cart_item_model.dart';

class Sale {
  final int? id;

  final String invoiceNumber;

  final int? customerId;

  final String customerName;

  final String paymentMethod;

  final double subtotal;

  final double taxAmount;

  final double discountAmount;

  final double grandTotal;

  final double paidAmount;

  final double balanceAmount;

  final String notes;

  final String status;

  final DateTime createdAt;

  final List<CartItem> items;

  const Sale({
    this.id,
    required this.invoiceNumber,
    this.customerId,
    this.customerName = "",
    required this.paymentMethod,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.grandTotal,
    required this.paidAmount,
    required this.balanceAmount,
    this.notes = "",
    this.status = "COMPLETED",
    required this.createdAt,
    required this.items,
  });

  Sale copyWith({
    int? id,
    String? invoiceNumber,
    int? customerId,
    String? customerName,
    String? paymentMethod,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    double? grandTotal,
    double? paidAmount,
    double? balanceAmount,
    String? notes,
    String? status,
    DateTime? createdAt,
    List<CartItem>? items,
  }) {
    return Sale(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}