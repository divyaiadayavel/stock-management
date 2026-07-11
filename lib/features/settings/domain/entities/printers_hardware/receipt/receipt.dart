import 'receipt_item.dart';

class Receipt {
  final String receiptId;
  final DateTime timestamp;
  final String? storeName;
  final String? storeAddress;
  final String? storePhone;
  final String? gstNumber;
  final String cashierName;
  final List<ReceiptItem> items;
  final double subTotal;
  final double taxAmount;
  final double grandTotal;
  final String? footerNote;
  final String? paymentMode;

  /// Path to a logo image file (e.g. from [BusinessProfile.logoPath]) to
  /// print at the top of the receipt. Ignored if null/empty, if the file
  /// can't be read, or if the printer's capabilities don't support images.
  final String? logoPath;

  const Receipt({
    required this.receiptId,
    required this.timestamp,
    this.storeName,
    this.storeAddress,
    this.storePhone,
    this.gstNumber,
    required this.cashierName,
    required this.items,
    required this.subTotal,
    required this.taxAmount,
    required this.grandTotal,
    this.footerNote,
    this.paymentMode,
    this.logoPath,
  });

  Receipt copyWith({
    String? receiptId,
    DateTime? timestamp,
    String? storeName,
    String? storeAddress,
    String? storePhone,
    String? gstNumber,
    String? cashierName,
    List<ReceiptItem>? items,
    double? subTotal,
    double? taxAmount,
    double? grandTotal,
    String? footerNote,
    String? paymentMode,
    String? logoPath,
  }) {
    return Receipt(
      receiptId: receiptId ?? this.receiptId,
      timestamp: timestamp ?? this.timestamp,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      storePhone: storePhone ?? this.storePhone,
      gstNumber: gstNumber ?? this.gstNumber,
      cashierName: cashierName ?? this.cashierName,
      items: items ?? this.items,
      subTotal: subTotal ?? this.subTotal,
      taxAmount: taxAmount ?? this.taxAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      footerNote: footerNote ?? this.footerNote,
      paymentMode: paymentMode ?? this.paymentMode,
      logoPath: logoPath ?? this.logoPath,
    );
  }
}