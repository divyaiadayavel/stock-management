import '../../../models/printers_hardware/receipt/receipt_model.dart';

/// Printer-independent receipt template.
///
/// This class prepares structured receipt data.
/// It contains NO ESC/POS commands and NO printer logic.
///
/// Supported outputs:
/// - Thermal (58mm / 80mm)
/// - PDF
/// - A4 Document
/// - Windows Printer
/// - Android Print Framework
/// - Future Cloud Printing

class DefaultReceiptTemplate {
  const DefaultReceiptTemplate();

  ReceiptTemplate build({
    required ReceiptModel receipt,
    required int paperWidth,
  }) {
    return ReceiptTemplate(
      paperWidth: paperWidth,

      business: BusinessTemplate(
        name: receipt.storeName ?? 'STORE NAME',
        address: receipt.storeAddress ?? '',
        phone: receipt.storePhone ?? '',
        gstNumber: receipt.gstNumber ?? '',
      ),

      receiptInfo: ReceiptInfoTemplate(
        receiptNumber: receipt.receiptId,
        dateTime: receipt.timestamp,
        cashier: receipt.cashierName,
      ),

      items: receipt.items
          .map(
            (e) => ReceiptItemTemplate(
              name: e.itemName,
              quantity: e.quantity,
              unitPrice: e.unitPrice,
              total: e.totalAmount,
            ),
          )
          .toList(),

      totals: ReceiptTotalsTemplate(
        subtotal: receipt.subTotal,
        tax: receipt.taxAmount,
        grandTotal: receipt.grandTotal,
      ),

      footer: FooterTemplate(
        message:
            receipt.footerNote ??
            'Thank you for shopping with us!',
      ),

      settings: ReceiptPrintSettings(
        printLogo: true,
        printBarcode: true,
        printQrCode: false,
        showGstNumber: true,
        showPhone: true,
        showAddress: true,
      ),
    );
  }
}

class ReceiptTemplate {
  final int paperWidth;

  final BusinessTemplate business;

  final ReceiptInfoTemplate receiptInfo;

  final List<ReceiptItemTemplate> items;

  final ReceiptTotalsTemplate totals;

  final FooterTemplate footer;

  final ReceiptPrintSettings settings;

  const ReceiptTemplate({
    required this.paperWidth,
    required this.business,
    required this.receiptInfo,
    required this.items,
    required this.totals,
    required this.footer,
    required this.settings,
  });
}

class BusinessTemplate {
  final String name;

  final String address;

  final String phone;

  final String gstNumber;

  const BusinessTemplate({
    required this.name,
    required this.address,
    required this.phone,
    required this.gstNumber,
  });
}

class ReceiptInfoTemplate {
  final String receiptNumber;

  final DateTime dateTime;

  final String cashier;

  const ReceiptInfoTemplate({
    required this.receiptNumber,
    required this.dateTime,
    required this.cashier,
  });
}

class ReceiptItemTemplate {
  final String name;

  final int quantity;

  final double unitPrice;

  final double total;

  const ReceiptItemTemplate({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });
}

class ReceiptTotalsTemplate {
  final double subtotal;

  final double tax;

  final double grandTotal;

  const ReceiptTotalsTemplate({
    required this.subtotal,
    required this.tax,
    required this.grandTotal,
  });
}

class FooterTemplate {
  final String message;

  const FooterTemplate({
    required this.message,
  });
}

class ReceiptPrintSettings {
  final bool printLogo;

  final bool printBarcode;

  final bool printQrCode;

  final bool showAddress;

  final bool showPhone;

  final bool showGstNumber;

  const ReceiptPrintSettings({
    required this.printLogo,
    required this.printBarcode,
    required this.printQrCode,
    required this.showAddress,
    required this.showPhone,
    required this.showGstNumber,
  });
}