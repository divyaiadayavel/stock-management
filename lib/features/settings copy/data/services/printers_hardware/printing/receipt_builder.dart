import 'dart:io';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../../models/printers_hardware/receipt/receipt_model.dart';
import '../../../models/printers_hardware/printer/printer_capability_model.dart';
import 'esc_pos_service.dart';

// ============================================================================
// 1. Receipt Style (fixed widths, single divider style)
// ============================================================================
class ReceiptStyle {
  final int charWidth;
  final int itemWidth;
  final int qtyWidth;
  final int priceWidth;
  final int amountWidth;
  final String divider;

  const ReceiptStyle._({
    required this.charWidth,
    required this.itemWidth,
    required this.qtyWidth,
    required this.priceWidth,
    required this.amountWidth,
    required this.divider,
  });

  factory ReceiptStyle.forPaper(PaperSize paper) {
    final width = paper == PaperSize.mm58 ? 32 : 48;
    return ReceiptStyle._(
      charWidth: width,
      itemWidth: paper == PaperSize.mm58 ? 11 : 23,
      qtyWidth: paper == PaperSize.mm58 ? 3 : 4,
      priceWidth: paper == PaperSize.mm58 ? 8 : 10,
      amountWidth: paper == PaperSize.mm58 ? 10 : 11,
      divider: '-' * width, // single line of dashes
    );
  }
}

// ============================================================================
// 2. Currency Formatter (with thousands separator, always 2 decimals)
// ============================================================================
String formatCurrency(double value) {
  final formatter = NumberFormat('#,##0.00', 'en_US');
  return formatter.format(value);
}

// ============================================================================
// 3. Word Wrap (handles long words)
// ============================================================================
List<String> wrapText(String text, int width) {
  if (text.isEmpty) return [];
  final words = text.split(RegExp(r'\s+'));
  List<String> lines = [];
  String current = '';

  for (final word in words) {
    if (word.length > width) {
      if (current.isNotEmpty) {
        lines.add(current);
        current = '';
      }
      int index = 0;
      while (index < word.length) {
        final end = (index + width < word.length) ? index + width : word.length;
        lines.add(word.substring(index, end));
        index = end;
      }
      continue;
    }

    if (current.isEmpty) {
      current = word;
    } else if ((current.length + word.length + 1) <= width) {
      current += ' $word';
    } else {
      lines.add(current);
      current = word;
    }
  }

  if (current.isNotEmpty) lines.add(current);
  return lines;
}

// ============================================================================
// 4. Main Receipt Builder (modular)
// ============================================================================
class ReceiptBuilder {
  final EscPosService _escPos;

  ReceiptBuilder({required EscPosService escPos}) : _escPos = escPos;

  // --------------------------------------------------------------------------
  // Public entry point
  // --------------------------------------------------------------------------
  Future<List<int>> buildReceiptBytes(
    ReceiptModel receipt,
    PrinterCapabilityModel capabilities,
  ) async {
    final paper = capabilities.paperWidthMm == 58 ? PaperSize.mm58 : PaperSize.mm80;
    final style = ReceiptStyle.forPaper(paper);
    final generator = await _escPos.createGenerator(paperSize: paper);

    List<int> bytes = [];

    // Hardware reset
    bytes += const [0x1B, 0x40];
    bytes += const [0x1D, 0x21, 0x00];

    // Build sections
    bytes += await _buildLogo(receipt.logoPath, generator, paper);
    bytes += await _buildStoreInfo(receipt, style, paper);
    bytes += await _buildInvoiceInfo(receipt, style, paper);
    bytes += await _buildItems(receipt.items, style, paper);
    bytes += await _buildSummary(receipt, style, paper);
    bytes += await _buildFooter(receipt, style, paper);

    // Cut
    bytes += await _escPos.feed(paperSize: paper, lines: 3);
    bytes += await _escPos.cut(paperSize: paper);

    return bytes;
  }

  // --------------------------------------------------------------------------
  // Section builders
  // --------------------------------------------------------------------------

  Future<List<int>> _buildLogo(
    String? logoPath,
    Generator generator,
    PaperSize paper,
  ) async {
    if (logoPath == null || logoPath.isEmpty) return [];
    try {
      final file = File(logoPath);
      if (!await file.exists()) return [];
      final imageBytes = await file.readAsBytes();
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) return [];

      final maxWidth = paper == PaperSize.mm58 ? 140 : 220;
      img.Image image = decoded;
      if (image.width > maxWidth) {
        final scale = maxWidth / image.width;
        image = img.copyResize(
          image,
          width: maxWidth,
          height: (image.height * scale).round(),
        );
      }
      return generator.image(image, align: PosAlign.center);
    } catch (_) {
      return [];
    }
  }

  Future<List<int>> _buildStoreInfo(
    ReceiptModel receipt,
    ReceiptStyle style,
    PaperSize paper,
  ) async {
    List<int> bytes = [];

    // Store name centered (e.g., "vignesh")
    if (receipt.storeName?.trim().isNotEmpty ?? false) {
      bytes += await _escPos.text(
        receipt.storeName!.trim(),
        styles: const PosStyles(align: PosAlign.center, bold: true),
        paperSize: paper,
      );
    }

    if (receipt.storeAddress?.trim().isNotEmpty ?? false) {
      final address = receipt.storeAddress!.trim().replaceAll('\n', ', ');
      bytes += await _escPos.center(address, paperSize: paper);
    }

    if (receipt.storePhone?.trim().isNotEmpty ?? false) {
      bytes += await _escPos.center('Ph - ${receipt.storePhone!.trim()}', paperSize: paper);
    }

    if (receipt.gstNumber?.trim().isNotEmpty ?? false) {
      bytes += await _escPos.center('GSTIN: ${receipt.gstNumber!.trim()}', paperSize: paper);
    }

    bytes += await _escPos.left(style.divider, paperSize: paper);
    return bytes;
  }

  Future<List<int>> _buildInvoiceInfo(
    ReceiptModel receipt,
    ReceiptStyle style,
    PaperSize paper,
  ) async {
    List<int> bytes = [];

    bytes += await _escPos.left('Invoice : ${receipt.receiptId}', paperSize: paper);
    bytes += await _escPos.left('Date    : ${_formatDate(receipt.timestamp)}', paperSize: paper);
    bytes += await _escPos.left('Time    : ${_formatTime(receipt.timestamp)}', paperSize: paper);
    bytes += await _escPos.left(style.divider, paperSize: paper);

    return bytes;
  }

  Future<List<int>> _buildItems(
    List<dynamic> items,
    ReceiptStyle style,
    PaperSize paper,
  ) async {
    List<int> bytes = [];

    // Table header (exact spacing: Item, Qty, Price, Amount)
    final header = 'Item'.padRight(style.itemWidth) +
        'Qty'.padLeft(style.qtyWidth) +
        'Price'.padLeft(style.priceWidth) +
        'Amount'.padLeft(style.amountWidth);
    bytes += await _escPos.text(
      header,
      styles: const PosStyles(bold: true),
      paperSize: paper,
    );
    bytes += await _escPos.left(style.divider, paperSize: paper);

    // Items
    for (final item in items) {
      final lines = wrapText(item.itemName.trim(), style.itemWidth);
      final qtyText = item.quantity.toString().padLeft(style.qtyWidth);
      final priceText = formatCurrency(item.unitPrice).padLeft(style.priceWidth);
      final amountText = formatCurrency(item.totalAmount).padLeft(style.amountWidth);

      for (int i = 0; i < lines.length; i++) {
        if (i == 0) {
          final row = lines[i].padRight(style.itemWidth) +
              qtyText +
              priceText +
              amountText;
          bytes += await _escPos.left(row, paperSize: paper);
        } else {
          // Continuation lines: only item name (indented)
          bytes += await _escPos.left(
            lines[i].padRight(style.itemWidth),
            paperSize: paper,
          );
        }
      }
    }

    bytes += await _escPos.left(style.divider, paperSize: paper);
    return bytes;
  }

  Future<List<int>> _buildSummary(
    ReceiptModel receipt,
    ReceiptStyle style,
    PaperSize paper,
  ) async {
    List<int> bytes = [];

    final subTotal = formatCurrency(receipt.subTotal);
    final cgst = formatCurrency(receipt.taxAmount / 2);
    final sgst = formatCurrency(receipt.taxAmount / 2);
    final grandTotal = formatCurrency(receipt.grandTotal);

    bytes += await _escPos.left(
      _twoColumns('Subtotal', subTotal, style.charWidth),
      paperSize: paper,
    );
    bytes += await _escPos.left(
      _twoColumns('CGST', cgst, style.charWidth),
      paperSize: paper,
    );
    bytes += await _escPos.left(
      _twoColumns('SGST', sgst, style.charWidth),
      paperSize: paper,
    );

    bytes += await _escPos.left(style.divider, paperSize: paper);

    // Total (bold)
    final totalLine = _twoColumns('TOTAL', grandTotal, style.charWidth);
    bytes += await _escPos.text(
      totalLine,
      styles: const PosStyles(bold: true),
      paperSize: paper,
    );

    bytes += await _escPos.left(style.divider, paperSize: paper);
    return bytes;
  }

  Future<List<int>> _buildFooter(
    ReceiptModel receipt,
    ReceiptStyle style,
    PaperSize paper,
  ) async {
    List<int> bytes = [];

    // Items count (with spacing: "Items    : 3")
    bytes += await _escPos.left(
      'Items    : ${receipt.items.length}',
      paperSize: paper,
    );

    // Payment (with spacing: "Payment : CASH")
    final payment = (receipt.paymentMode?.trim().isNotEmpty ?? false)
        ? receipt.paymentMode!.trim().toUpperCase()
        : 'CASH';
    bytes += await _escPos.left(
      'Payment : $payment',
      paperSize: paper,
    );

    // Thank you messages (centered)
    bytes += await _escPos.text(
      'Thank You!',
      styles: const PosStyles(align: PosAlign.center, bold: true),
      paperSize: paper,
    );
    bytes += await _escPos.text(
      'Visit Again',
      styles: const PosStyles(align: PosAlign.center, bold: true),
      paperSize: paper,
    );
    bytes += await _escPos.center(receipt.receiptId, paperSize: paper);

    return bytes;
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  String _twoColumns(String left, String right, int width) {
    final spaces = width - left.length - right.length;
    return left + (spaces > 0 ? ' ' * spaces : ' ') + right;
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '$day-${months[d.month - 1]}-${d.year}';
  }

  String _formatTime(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final period = d.hour >= 12 ? 'PM' : 'AM';
    final minute = d.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }
}