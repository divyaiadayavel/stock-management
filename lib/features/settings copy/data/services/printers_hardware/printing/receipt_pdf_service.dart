import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../domain/entities/printers_hardware/receipt/receipt.dart';

/// Renders a [Receipt] as a printable Pdf document for inkjet/laser
/// printers ("system" connection type), as opposed to the raw ESC/POS byte
/// stream used for thermal printers (see [ReceiptBuilder]).
///
/// Deliberately rendered as monospace plain text (not a bordered pw.Table)
/// so a "system" printer produces the same classic thermal-receipt look as
/// [ReceiptBuilder] does for Bluetooth/WiFi/USB printers.
class ReceiptPdfService {
  static const int _width = 36; // characters per line

  Future<Uint8List> buildReceiptPdf(
    Receipt receipt, {
    PdfPageFormat pageFormat = PdfPageFormat.a5,
  }) async {
    final doc = pw.Document();
    final font = pw.Font.courier();
    final boldFont = pw.Font.courierBold();

    final logoImage = await _loadLogo(receipt.logoPath);

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat.copyWith(
          marginLeft: 20,
          marginRight: 20,
          marginTop: 16,
          marginBottom: 16,
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logoImage != null) ...[
              pw.Image(logoImage, width: 70, height: 70, fit: pw.BoxFit.contain),
              pw.SizedBox(height: 6),
            ],
            pw.Text(
              (receipt.storeName?.trim().isNotEmpty ?? false)
                  ? receipt.storeName!.trim()
                  : 'STORE NAME',
              style: pw.TextStyle(font: boldFont, fontSize: 13),
            ),
            if (receipt.storeAddress?.trim().isNotEmpty ?? false)
              for (final line in receipt.storeAddress!.trim().split('\n'))
                if (line.trim().isNotEmpty)
                  pw.Text(line.trim(), style: pw.TextStyle(font: font, fontSize: 9)),
            if (receipt.gstNumber?.trim().isNotEmpty ?? false)
              pw.Text('GSTIN: ${receipt.gstNumber!.trim()}',
                  style: pw.TextStyle(font: font, fontSize: 9)),
            pw.SizedBox(height: 6),
            pw.Text(
              _buildBodyText(receipt),
              style: pw.TextStyle(font: font, fontSize: 9.5, lineSpacing: 2),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  /// Everything below the store header, as one monospaced block so columns
  /// line up the same way they do on a real thermal printer.
  String _buildBodyText(Receipt receipt) {
    final buffer = StringBuffer();
    final rule = '-' * _width;

    buffer.writeln(rule);
    buffer.writeln(
      'DATE: ${_formatDate(receipt.timestamp)}  ${_formatTime(receipt.timestamp)}',
    );
    buffer.writeln('INV NO: #${receipt.receiptId}');
    buffer.writeln(rule);
    buffer.writeln(_itemRowText('ITEM', 'QTY', 'RATE', 'TOTAL'));
    buffer.writeln();

    for (final item in receipt.items) {
      buffer.writeln(_itemRowText(
        item.itemName,
        '${item.quantity}',
        item.unitPrice.toStringAsFixed(2),
        item.totalAmount.toStringAsFixed(2),
      ));
    }
    buffer.writeln(rule);

    final halfTax = receipt.taxAmount / 2;
    final halfTaxPercent =
        receipt.subTotal > 0 ? (receipt.taxAmount / receipt.subTotal * 50) : 0;
    final percentLabel =
        halfTaxPercent > 0 ? ' (${halfTaxPercent.round()}%)' : '';

    buffer.writeln(_twoColText('SUB TOTAL:', receipt.subTotal.toStringAsFixed(2)));
    buffer.writeln(_twoColText('CGST$percentLabel:', halfTax.toStringAsFixed(2)));
    buffer.writeln(_twoColText('SGST$percentLabel:', halfTax.toStringAsFixed(2)));
    buffer.writeln(rule);
    buffer.writeln(_twoColText('TOTAL AMOUNT:', receipt.grandTotal.toStringAsFixed(2)));
    buffer.writeln(rule);
    buffer.writeln();
    buffer.writeln(_centerText(
      'Payment Mode: ${(receipt.paymentMode?.trim().isNotEmpty ?? false) ? receipt.paymentMode!.trim() : 'Cash'}',
    ));
    buffer.write(_centerText(
      (receipt.footerNote?.trim().isNotEmpty ?? false)
          ? receipt.footerNote!.trim()
          : 'THANK YOU, VISIT AGAIN!',
    ));

    return buffer.toString();
  }

  Future<pw.MemoryImage?> _loadLogo(String? logoPath) async {
    final path = logoPath?.trim();
    if (path == null || path.isEmpty) return null;
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  String _centerText(String text) {
    if (text.length >= _width) return text;
    final totalPad = _width - text.length;
    final left = totalPad ~/ 2;
    return ' ' * left + text;
  }

  /// name(14) qty(5, right) rate(8, right) total(9, right) = 36 chars.
  String _itemRowText(String name, String qty, String rate, String total) {
    final namePart = name.length > 14 ? name.substring(0, 14) : name.padRight(14);
    final qtyPart = qty.padLeft(5);
    final ratePart = rate.padLeft(8);
    final totalPart = total.padLeft(9);
    return '$namePart$qtyPart$ratePart$totalPart';
  }

  String _twoColText(String label, String value) {
    final valuePart = value.padLeft(12);
    final labelWidth = _width - 12;
    final labelPart = label.length > labelWidth ? label.substring(0, labelWidth) : label.padRight(labelWidth);
    return '$labelPart$valuePart';
  }

  String _formatDate(DateTime value) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final day = value.day.toString().padLeft(2, '0');
    return '$day-${months[value.month - 1]}-${value.year}';
  }

  String _formatTime(DateTime value) {
    final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final period = value.hour >= 12 ? 'PM' : 'AM';
    final minute = value.minute.toString().padLeft(2, '0');
    return 'TIME: ${hour12.toString().padLeft(2, '0')}:$minute $period';
  }
}