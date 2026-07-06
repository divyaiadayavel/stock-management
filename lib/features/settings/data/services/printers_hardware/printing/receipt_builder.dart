import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../../../models/printers_hardware/receipt/receipt_model.dart';
import '../../../models/printers_hardware/printer/printer_capability_model.dart';
import 'esc_pos_service.dart';

class ReceiptBuilder {
  final EscPosService _escPos;

  ReceiptBuilder({required EscPosService escPos}) : _escPos = escPos;

  Future<List<int>> buildReceiptBytes(
    ReceiptModel receipt,
    PrinterCapabilityModel capabilities,
  ) async {
    final paperSize = capabilities.paperWidthMm == 58 ? PaperSize.mm58 : PaperSize.mm80;
    final generator = await _escPos.createGenerator(paperSize: paperSize);
    List<int> bytes = [];

    // --- Header ---
    bytes += await _escPos.center(
      receipt.storeName ?? 'STORE NAME',
      paperSize: paperSize,
    );
    bytes += await _escPos.text('Receipt ID: ${receipt.receiptId}',
        styles: const PosStyles(align: PosAlign.center), paperSize: paperSize);
    bytes += await _escPos.text(
        'Date: ${receipt.timestamp.toString().substring(0, 16)}',
        styles: const PosStyles(align: PosAlign.center), paperSize: paperSize);
    bytes += await _escPos.text('Cashier: ${receipt.cashierName}',
        styles: const PosStyles(align: PosAlign.center), paperSize: paperSize);
    bytes += await _escPos.horizontalRule(paperSize: paperSize);

    // --- Items ---
    for (var item in receipt.items) {
      bytes += generator.row([
        PosColumn(text: item.itemName, width: 6),
        PosColumn(text: '${item.quantity}x', width: 2, styles: const PosStyles(align: PosAlign.right)),
        PosColumn(text: '\$${item.totalAmount.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += await _escPos.horizontalRule(paperSize: paperSize);

    // --- Totals ---
    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 6),
      PosColumn(text: '\$${receipt.subTotal.toStringAsFixed(2)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Tax', width: 6),
      PosColumn(text: '\$${receipt.taxAmount.toStringAsFixed(2)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
      PosColumn(text: '\$${receipt.grandTotal.toStringAsFixed(2)}', width: 6, styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2)),
    ]);

    // --- Footer ---
    bytes += await _escPos.feed(paperSize: paperSize, lines: 1);
    if (capabilities.supportsBarcode) {
      bytes += generator.barcode(Barcode.code128(receipt.receiptId.split('')));
    }
    bytes += await _escPos.feed(paperSize: paperSize, lines: 2);
    bytes += await _escPos.cut(paperSize: paperSize);

    return bytes;
  }
}