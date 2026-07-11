import 'package:collection/collection.dart';
import 'receipt_item_model.dart';
import '../../../../domain/entities/printers_hardware/receipt/receipt.dart';
import '../../../../domain/entities/printers_hardware/receipt/receipt_item.dart';
class ReceiptModel extends Receipt {
  const ReceiptModel({
    required super.receiptId,
    required super.timestamp,
    required super.cashierName,
    required super.items,
    required super.subTotal,
    required super.taxAmount,
    required super.grandTotal,
    super.storeName,
    super.storeAddress,
    super.storePhone,
    super.gstNumber,
    super.footerNote,
    super.paymentMode,
    super.logoPath,
  });

  factory ReceiptModel.fromEntity(Receipt entity) {
    return ReceiptModel(
      receiptId: entity.receiptId,
      timestamp: entity.timestamp,
      cashierName: entity.cashierName,
      items: entity.items
          .map((e) => e is ReceiptItemModel ? e : ReceiptItemModel.fromEntity(e))
          .toList(),
      subTotal: entity.subTotal,
      taxAmount: entity.taxAmount,
      grandTotal: entity.grandTotal,
      storeName: entity.storeName,
      storeAddress: entity.storeAddress,
      storePhone: entity.storePhone,
      gstNumber: entity.gstNumber,
      footerNote: entity.footerNote,
      paymentMode: entity.paymentMode,
      logoPath: entity.logoPath,
    );
  }

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      receiptId: json['receiptId']?.toString() ?? '',
      timestamp: _parseDateTime(json['timestamp']) ?? DateTime.now(),
      cashierName: json['cashierName']?.toString() ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => ReceiptItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      storeName: json['storeName']?.toString(),
      storeAddress: json['storeAddress']?.toString(),
      storePhone: json['storePhone']?.toString(),
      gstNumber: json['gstNumber']?.toString(),
      footerNote: json['footerNote']?.toString(),
      paymentMode: json['paymentMode']?.toString(),
      logoPath: json['logoPath']?.toString(),
    );
  }

  // ✅ No @override – entity does not define toJson()
  Map<String, dynamic> toJson() {
    return {
      'receiptId': receiptId,
      'timestamp': timestamp.toIso8601String(),
      'cashierName': cashierName,
      'items': items.map((e) => ReceiptItemModel.fromEntity(e).toJson()).toList(),
      'subTotal': subTotal,
      'taxAmount': taxAmount,
      'grandTotal': grandTotal,
      'storeName': storeName,
      'storeAddress': storeAddress,
      'storePhone': storePhone,
      'gstNumber': gstNumber,
      'footerNote': footerNote,
      'paymentMode': paymentMode,
      'logoPath': logoPath,
    };
  }

  // ✅ @override is correct – entity defines copyWith()
  @override
  ReceiptModel copyWith({
    String? receiptId,
    DateTime? timestamp,
    String? cashierName,
    List<ReceiptItem>? items,
    double? subTotal,
    double? taxAmount,
    double? grandTotal,
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? gstNumber,
    String? footerNote,
    String? paymentMode,
    String? logoPath,
  }) {
    return ReceiptModel(
      receiptId: receiptId ?? this.receiptId,
      timestamp: timestamp ?? this.timestamp,
      cashierName: cashierName ?? this.cashierName,
      items: items ?? this.items,
      subTotal: subTotal ?? this.subTotal,
      taxAmount: taxAmount ?? this.taxAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      storePhone: storePhone ?? this.storePhone,
      gstNumber: gstNumber ?? this.gstNumber,
      footerNote: footerNote ?? this.footerNote,
      paymentMode: paymentMode ?? this.paymentMode,
      logoPath: logoPath ?? this.logoPath,
    );
  }

  // ✅ No @override – entity does not define toEntity()
  Receipt toEntity() => this;

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReceiptModel) return false;
    return runtimeType == other.runtimeType &&
        receiptId == other.receiptId &&
        timestamp == other.timestamp &&
        cashierName == other.cashierName &&
        const ListEquality().equals(items, other.items) &&
        subTotal == other.subTotal &&
        taxAmount == other.taxAmount &&
        grandTotal == other.grandTotal &&
        storeName == other.storeName &&
        storeAddress == other.storeAddress &&
        storePhone == other.storePhone &&
        gstNumber == other.gstNumber &&
        footerNote == other.footerNote &&
        paymentMode == other.paymentMode &&
        logoPath == other.logoPath;
  }

  @override
  int get hashCode =>
      receiptId.hashCode ^
      timestamp.hashCode ^
      cashierName.hashCode ^
      const ListEquality().hash(items) ^
      subTotal.hashCode ^
      taxAmount.hashCode ^
      grandTotal.hashCode ^
      storeName.hashCode ^
      storeAddress.hashCode ^
      storePhone.hashCode ^
      gstNumber.hashCode ^
      footerNote.hashCode ^
      paymentMode.hashCode ^
      logoPath.hashCode;
}