// lib/features/sales/data/models/sale_model.dart
import '../../domain/entities/sale.dart';
import 'cart_item_model.dart';

class SalePayment {
  final int id;
  final int saleId;
  final String paymentMethod;
  final double amount;
  final String? referenceNumber;
  final String? paymentDate;
  final String? remarks;

  SalePayment({
    required this.id,
    required this.saleId,
    required this.paymentMethod,
    required this.amount,
    this.referenceNumber,
    this.paymentDate,
    this.remarks,
  });

  factory SalePayment.fromMap(Map<String, dynamic> map) {
    return SalePayment(
      id: map['id'] ?? 0,
      saleId: map['sale_id'] ?? 0,
      paymentMethod: map['payment_method'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      referenceNumber: map['reference_number']?.toString(),
      paymentDate: map['payment_date']?.toString(),
      remarks: map['remarks']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'payment_method': paymentMethod,
      'amount': amount,
      'reference_number': referenceNumber,
      'payment_date': paymentDate,
      'remarks': remarks,
    };
  }
}

class SaleModel extends Sale {
  final DateTime invoiceDate;
  final double roundOff;
  final String paymentStatus;
  final String invoiceStatus;
  final String? remarks;
  final int? createdBy;
  final DateTime updatedAt;
  final List<SalePayment> payments;
  final double recordedPaymentTotal;

  SaleModel({
    super.id,
    required super.invoiceNumber,
    super.customerId,
    super.customerName = "",
    required this.invoiceDate,
    required super.paymentMethod,
    required super.subtotal,
    required super.taxAmount,
    required super.discountAmount,
    required this.roundOff,
    required super.grandTotal,
    required super.paidAmount,
    required super.balanceAmount,
    required this.paymentStatus,
    required this.invoiceStatus,
    this.remarks,
    this.createdBy,
    required super.createdAt,
    required this.updatedAt,
    required super.items,
    super.notes = "",
    super.status = "COMPLETED",
    this.payments = const [],
    this.recordedPaymentTotal = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) "id": id,
      "invoice_number": invoiceNumber,
      "customer_id": customerId,
      "invoice_date": invoiceDate.toIso8601String(),
      "subtotal": subtotal,
      "discount_amount": discountAmount,
      "tax_amount": taxAmount,
      "round_off": roundOff,
      "grand_total": grandTotal,
      "payment_method": paymentMethod,
      "payment_status": paymentStatus,
      "invoice_status": invoiceStatus,
      "remarks": remarks,
      "created_by": createdBy,
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt.toIso8601String(),
      "payments": payments.map((e) => e.toMap()).toList(),
      "recorded_payment_total": recordedPaymentTotal,
      "items": items.map((e) => (e as CartItem).toMap()).toList(),
    };
  }

  factory SaleModel.fromMap(Map<String, dynamic> map) {
    var rawPayments = map["payments"] as List? ?? [];
    List<SalePayment> parsedPayments = rawPayments
        .map((e) => SalePayment.fromMap(e as Map<String, dynamic>))
        .toList();

    return SaleModel(
      id: map["id"] != null ? int.tryParse(map["id"].toString()) : null,
      invoiceNumber: map["invoice_number"]?.toString() ?? "",
      customerId: map["customer_id"] != null
          ? int.tryParse(map["customer_id"].toString())
          : null,
      customerName: map["customer_name"]?.toString() ?? "Walk-in Customer",
      invoiceDate: DateTime.parse(map["invoice_date"] ?? map["created_at"]),
      paymentMethod: map["payment_method"]?.toString() ?? "CASH",
      subtotal: (map["subtotal"] as num?)?.toDouble() ?? 0,
      taxAmount: (map["tax_amount"] as num?)?.toDouble() ?? 0,
      discountAmount: (map["discount_amount"] as num?)?.toDouble() ?? 0,
      roundOff: (map["round_off"] as num?)?.toDouble() ?? 0,
      grandTotal: (map["grand_total"] as num?)?.toDouble() ?? 0,
      paidAmount: (map["paid_amount"] as num?)?.toDouble() ?? 0.0,
      balanceAmount: (map["balance_amount"] as num?)?.toDouble() ?? 0.0,
      paymentStatus: map["payment_status"]?.toString() ?? "PAID",
      invoiceStatus: map["invoice_status"]?.toString() ?? "FINAL",
      remarks: map["remarks"]?.toString(),
      createdBy: map["created_by"] != null
          ? int.tryParse(map["created_by"].toString())
          : null,
      createdAt: DateTime.parse(map["created_at"] ?? map["invoice_date"]),
      updatedAt: DateTime.parse(
        map["updated_at"] ??
            map["created_at"] ??
            DateTime.now().toIso8601String(),
      ),
      payments: parsedPayments,
      recordedPaymentTotal:
          (map["recorded_payment_total"] as num?)?.toDouble() ?? 0.0,
      items:
          (map["items"] as List?)
              ?.map((e) => CartItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
