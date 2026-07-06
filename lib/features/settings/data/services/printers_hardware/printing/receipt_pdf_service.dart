import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../domain/entities/printers_hardware/receipt/receipt.dart';

/// Renders a [Receipt] as a printable Pdf document for inkjet/laser
/// printers, as opposed to the raw ESC/POS byte stream used for thermal
/// printers (see [ReceiptBuilder]).
class ReceiptPdfService {
  Future<Uint8List> buildReceiptPdf(
    Receipt receipt, {
    PdfPageFormat pageFormat = PdfPageFormat.a5,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat.copyWith(
          marginLeft: 16,
          marginRight: 16,
          marginTop: 16,
          marginBottom: 16,
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: pw.Text(
                receipt.storeName?.trim().isNotEmpty == true
                    ? receipt.storeName!.trim()
                    : 'STORE NAME',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ),
            if (receipt.storeAddress?.trim().isNotEmpty == true)
              pw.Center(
                child: pw.Text(receipt.storeAddress!.trim(),
                    style: const pw.TextStyle(fontSize: 9)),
              ),
            if (receipt.storePhone?.trim().isNotEmpty == true)
              pw.Center(
                child: pw.Text('Phone: ${receipt.storePhone!.trim()}',
                    style: const pw.TextStyle(fontSize: 9)),
              ),
            if (receipt.gstNumber?.trim().isNotEmpty == true)
              pw.Center(
                child: pw.Text('GSTIN: ${receipt.gstNumber!.trim()}',
                    style: const pw.TextStyle(fontSize: 9)),
              ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Receipt: ${receipt.receiptId}',
                    style: const pw.TextStyle(fontSize: 9)),
                pw.Text(_formatDate(receipt.timestamp),
                    style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
            pw.Text('Cashier: ${receipt.cashierName}',
                style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 0.8),
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(5),
                1: pw.FlexColumnWidth(1.4),
                2: pw.FlexColumnWidth(2.2),
              },
              children: [
                pw.TableRow(children: [
                  pw.Text('Item', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Qty', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                  pw.Text('Amount', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                ]),
                pw.TableRow(children: [
                  pw.SizedBox(height: 4),
                  pw.SizedBox(height: 4),
                  pw.SizedBox(height: 4),
                ]),
                for (final item in receipt.items)
                  pw.TableRow(children: [
                    pw.Text(item.itemName, style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('${item.quantity}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right),
                    pw.Text(item.totalAmount.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right),
                  ]),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 0.8),
            _totalsRow('Subtotal', receipt.subTotal),
            _totalsRow('Tax', receipt.taxAmount),
            pw.SizedBox(height: 4),
            _totalsRow('TOTAL', receipt.grandTotal, bold: true, fontSize: 12),
            pw.SizedBox(height: 14),
            if (receipt.footerNote?.trim().isNotEmpty == true)
              pw.Center(
                child: pw.Text(
                  receipt.footerNote!.trim(),
                  style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
                  textAlign: pw.TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  pw.Widget _totalsRow(String label, double amount, {bool bold = false, double fontSize = 10}) {
    final style = pw.TextStyle(
      fontSize: fontSize,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(amount.toStringAsFixed(2), style: style),
      ],
    );
  }

  String _formatDate(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} ${two(value.hour)}:${two(value.minute)}';
  }
}
