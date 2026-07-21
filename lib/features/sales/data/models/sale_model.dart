// lib/features/sales/data/models/sale_model.dart
import '../../domain/entities/sale.dart';
import 'cart_item_model.dart';

class SaleModel extends Sale {
  final DateTime invoiceDate;
  final double roundOff;
  final String paymentStatus;
  final String invoiceStatus;
  final String? remarks;
  final int? createdBy;
  final DateTime updatedAt;

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
      // paidAmount and balanceAmount are not stored in the DB – they are omitted
      "items": items.map((e) => (e as CartItem).toMap()).toList(),
    };
  }

  factory SaleModel.fromMap(Map<String, dynamic> map) {
    return SaleModel(
      id: map["id"] != null ? int.tryParse(map["id"].toString()) : null,
      invoiceNumber: map["invoice_number"]?.toString() ?? "",
      customerId: map["customer_id"] != null ? int.tryParse(map["customer_id"].toString()) : null,
      customerName: map["customer_name"]?.toString() ?? "Walk-in Customer",
      invoiceDate: DateTime.parse(map["invoice_date"] ?? map["created_at"]),
      paymentMethod: map["payment_method"]?.toString() ?? "CASH",
      subtotal: (map["subtotal"] as num?)?.toDouble() ?? 0,
      taxAmount: (map["tax_amount"] as num?)?.toDouble() ?? 0,
      discountAmount: (map["discount_amount"] as num?)?.toDouble() ?? 0,
      roundOff: (map["round_off"] as num?)?.toDouble() ?? 0,
      grandTotal: (map["grand_total"] as num?)?.toDouble() ?? 0,
      paidAmount: (map["paid_amount"] as num?)?.toDouble() ?? 0,
      balanceAmount: (map["balance_amount"] as num?)?.toDouble() ?? 0,
      paymentStatus: map["payment_status"]?.toString() ?? "PAID",
      invoiceStatus: map["invoice_status"]?.toString() ?? "FINAL",
      remarks: map["remarks"]?.toString(),
      createdBy: map["created_by"] != null ? int.tryParse(map["created_by"].toString()) : null,
      createdAt: DateTime.parse(map["created_at"] ?? map["invoice_date"]),
      updatedAt: DateTime.parse(map["updated_at"] ?? map["created_at"] ?? DateTime.now().toIso8601String()),
      items: (map["items"] as List?)
              ?.map((e) => CartItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}